# 💬 Messaging System Documentation

> **Status**: 📋 Planning Complete | **Estimated Effort**: 40-50 hours (1 week)

## 📖 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
  - [Design Principles](#design-principles)
  - [Database Schema](#database-schema)
- [Context API](#context-api-homesitemessaging)
- [Features](#features)
- [Safety Features](#safety-features)
- [UI Components](#ui-components)
- [Security Patterns](#security-patterns)
- [Performance Considerations](#performance-considerations)
- [Testing Strategy](#testing-strategy)
- [Common Patterns](#common-patterns)
- [Data Retention & Legal Compliance](#data-retention--legal-compliance)
- [Monitoring & Alerts](#monitoring--alerts)
- [Future Enhancements](#future-enhancements)
- [Troubleshooting](#troubleshooting)
- [Configuration](#configuration)

---

## 🎯 Overview

The Homesite messaging system enables content collaboration between users through secure, real-time 1-on-1 conversations with moderate proactive moderation.

**✅ Purpose**: Content collaboration (discussing posts, giving feedback, collaborating on content)
**❌ Not intended for**: General social chat or public discussions

## Architecture

### Design Principles

1. **Scope-First Security**: All operations require `%Scope{}` and enforce participant verification
2. **Permanent Storage**: Messages are never deleted (legal/audit requirement), only hidden from UI
3. **Real-Time Updates**: LiveView + PubSub for instant message delivery
4. **Proactive Moderation**: Rate limiting, spam filtering, blocking, and admin review system

### Database Schema

#### Tables

**1. conversations**
```elixir
# Stores conversation metadata
id               - Primary key
title            - Optional (for groups)
is_group         - Boolean (false for 1-on-1)
inserted_at      - Creation timestamp
updated_at       - Last update timestamp
```

**2. conversation_participants**
```elixir
# Junction table with read tracking
id               - Primary key
conversation_id  - FK to conversations
user_id          - FK to users
last_read_at     - Timestamp of last read message
joined_at        - When user joined conversation
inserted_at      - Creation timestamp
updated_at       - Last update timestamp

# Constraints
UNIQUE(conversation_id, user_id)
INDEX(user_id)
PARTIAL INDEX(user_id, conversation_id) WHERE has_unread
```

**3. messages**
```elixir
# Stores all messages (permanent)
id                  - Primary key
conversation_id     - FK to conversations
sender_id           - FK to users
body                - Text content (1-5000 chars)
hidden_at           - Soft delete timestamp (UI only)
hidden_by_user_id   - FK to users (who hid it)
edited_at           - Edit timestamp
flagged_at          - Flagged for moderation timestamp
flagged_by_user_id  - FK to users (who flagged)
flagged_reason      - String (why flagged)
reviewed_at         - Admin review timestamp
reviewed_by_user_id - FK to users (admin who reviewed)
inserted_at         - Creation timestamp
updated_at          - Last update timestamp

# Indexes
INDEX(conversation_id, inserted_at)  # Message history
INDEX(sender_id)                      # User's messages
PARTIAL INDEX(flagged_at) WHERE flagged_at IS NOT NULL AND reviewed_at IS NULL
```

**4. blocked_users**
```elixir
# User blocking for safety
id          - Primary key
blocker_id  - FK to users (who blocked)
blocked_id  - FK to users (who was blocked)
reason      - Optional string
inserted_at - Creation timestamp
updated_at  - Last update timestamp

# Constraints
UNIQUE(blocker_id, blocked_id)
INDEX(blocked_id)  # Reverse lookups
```

## Context API: `Homesite.Messaging`

### PubSub Functions

```elixir
# Subscribe to all conversations for a user
subscribe_conversations(%Scope{}) :: :ok

# Subscribe to specific conversation (verifies participant)
subscribe_conversation(%Scope{}, conversation_id) :: :ok

# Broadcast patterns:
# {:new_message, %Message{}}
# {:message_updated, %Message{}}
# {:conversation_updated, %Conversation{}}
```

### Conversation Functions

```elixir
# List user's conversations with unread counts
list_conversations(%Scope{}) :: [%{
  conversation: %Conversation{},
  unread_count: integer(),
  last_message_at: DateTime.t() | nil
}]

# Get single conversation (verifies participant)
get_conversation!(%Scope{}, id) :: %Conversation{}
# Raises MatchError if not participant

# Create 1-on-1 conversation
create_conversation(%Scope{}, other_user_id, attrs \\ %{}) ::
  {:ok, %Conversation{}} | {:error, :user_blocked} | {:error, %Ecto.Changeset{}}

# Check if user is participant
is_participant?(%Scope{}, conversation_id) :: boolean()
```

**Key Behaviors:**
- `create_conversation/3` returns existing conversation if one exists between users
- Checks blocking status before creating conversation
- Uses transaction to ensure atomic participant creation

### Message Functions

```elixir
# List messages in conversation (paginated)
list_messages(%Scope{}, conversation_id, opts \\ []) :: [%Message{}]
# Options: limit (default 50), offset (default 0)
# Verifies participant before listing
# Filters out hidden messages

# Send message
send_message(%Scope{}, conversation_id, attrs) ::
  {:ok, %Message{}} | {:error, %Ecto.Changeset{}}
# Validates spam keywords
# Broadcasts to conversation topic
# Notifies all participants

# Hide message (soft delete, UI only)
hide_message(%Scope{}, message_id) ::
  {:ok, %Message{}} | {:error, %Ecto.Changeset{}}
# Only sender can hide their own message
# Sets hidden_at timestamp

# Mark conversation as read
mark_as_read(%Scope{}, conversation_id) :: :ok
# Updates last_read_at for current user
```

### Blocking Functions

```elixir
# Block user
block_user(%Scope{}, blocked_user_id, reason \\ nil) ::
  {:ok, %BlockedUser{}} | {:error, %Ecto.Changeset{}}

# Unblock user
unblock_user(%Scope{}, blocked_user_id) :: :ok

# List blocked users
list_blocked_users(%Scope{}) :: [%BlockedUser{}]

# Check if users have blocked each other (bidirectional)
is_blocked?(%Scope{}, other_user_id) :: boolean()
```

### Moderation Functions (Admin Only)

```elixir
# Flag message for review
flag_message(%Scope{}, message_id, reason) ::
  {:ok, %Message{}} | {:error, %Ecto.Changeset{}}
# Any participant can flag messages

# List flagged messages (admin only)
list_flagged_messages(%Scope{admin_override?: true}) :: [%Message{}]

# Mark message as reviewed (admin only)
review_message(%Scope{admin_override?: true}, message_id) ::
  {:ok, %Message{}} | {:error, %Ecto.Changeset{}}
```

## Safety Features

### 1. Rate Limiting

**Location**: Router pipeline (`lib/homesite_web/router.ex`)

```elixir
pipeline :rate_limit_messaging do
  plug Hammer.Plug,
    rate_limit: {"messaging:send", 60_000, 50},  # 50 messages per minute
    by: {:conn, &__MODULE__.get_ip/1}
end
```

**Applied to**: Message sending routes

### 2. Spam Detection

**Location**: Message changeset validation

**Spam Keywords**:
- "viagra", "casino", "lottery", "winner", "congratulations"
- "click here", "buy now", "limited time", "act now"

**Implementation**:
```elixir
defp contains_spam_keywords?(body) do
  spam_keywords = [...]
  normalized = String.downcase(body)
  Enum.any?(spam_keywords, &String.contains?(normalized, &1))
end
```

**Result**: Message creation fails with validation error

### 3. Blocking System

**Behavior**:
- Bidirectional: If A blocks B, neither can message the other
- Prevents conversation creation
- Existing conversations remain visible but no new messages
- Optional reason tracking for moderation review

### 4. Moderation Queue

**Workflow**:
1. User flags inappropriate message
2. Message appears in admin moderation queue
3. Admin reviews and marks as reviewed
4. Message remains visible (no auto-deletion)

**Admin Access**: Via `/admin/moderation` (requires admin role)

## UI Components

### Conversation List (`/conversations`)

**File**: `lib/homesite_web/live/conversation_live/index.ex`

**Features**:
- List all conversations for current user
- Unread count badges
- Last message timestamp ("5m ago", "2h ago")
- "New Conversation" button
- Real-time updates when messages arrive

**Layout**:
```
┌─────────────────────────────────────┐
│  Messages               [+ New]     │
├─────────────────────────────────────┤
│  👤 Jane Doe                [2]     │
│     5 minutes ago                   │
├─────────────────────────────────────┤
│  👤 John Smith                      │
│     2 hours ago                     │
└─────────────────────────────────────┘
```

### Message Thread (`/conversations/:id`)

**File**: `lib/homesite_web/live/conversation_live/show.ex`

**Features**:
- Chat bubble interface (DaisyUI chat components)
- Real-time message delivery
- Auto-scroll to bottom on new messages
- Mark as read on mount
- Hide/Report buttons per message
- Message composition textarea

**Layout**:
```
┌─────────────────────────────────────┐
│  Jane Doe                [← Back]   │
├─────────────────────────────────────┤
│  [Other User]                       │
│  ┌───────────────────┐              │
│  │ Hey, how are you? │              │
│  └───────────────────┘              │
│                                     │
│              ┌──────────────────┐   │
│              │ I'm good thanks! │   │
│              └──────────────────┘   │
│              [Hide] [Report]        │
├─────────────────────────────────────┤
│  Type message... [Send →]          │
└─────────────────────────────────────┘
```

### New Conversation (`/conversations/new`)

**File**: `lib/homesite_web/live/conversation_live/new.ex`

**Features**:
- Search users by username/email
- Select user to start conversation
- Redirects to conversation after creation
- Shows "User has blocked you" error if applicable

### Admin Moderation (`/admin/moderation`)

**File**: `lib/homesite_web/live/admin_live/moderation.ex`

**Features**:
- List all flagged messages
- Show sender, flagger, reason
- Display full message content
- "Mark as Reviewed" action
- Admin-only access (via on_mount hook)

## Security Patterns

### Scope Isolation

**Pattern**: All context functions enforce participant verification

```elixir
def get_conversation!(%Scope{} = scope, id) do
  conversation = Repo.get!(Conversation, id) |> Repo.preload(participants: :user)

  # Verify scope user is participant
  participant_ids = Enum.map(conversation.participants, & &1.user_id)
  true = scope.user.id in participant_ids  # Raises MatchError if not

  conversation
end
```

**Critical**: The `true = condition` pattern ensures MatchError is raised when authorization fails.

### Security Tests

**File**: `test/homesite_web/messaging_security_test.exs`

**Required Tests**:
1. User A cannot view User B's conversation
2. User A cannot send messages in User B's conversation
3. User A cannot list User B's messages
4. Blocked users cannot start conversations
5. User cannot mark other user's message as read
6. User A cannot update User B's message
7. Spam keywords are rejected
8. User cannot block themselves

**Pattern**:
```elixir
test "user A cannot view user B's conversation" do
  user_a = user_fixture()
  user_b = user_fixture()
  user_c = user_fixture()

  scope_b = %Scope{user: user_b}
  {:ok, conversation} = Messaging.create_conversation(scope_b, user_c.id)

  scope_a = %Scope{user: user_a}

  assert_raise MatchError, fn ->
    Messaging.get_conversation!(scope_a, conversation.id)
  end
end
```

## Performance Considerations

### Database Indexes

1. **Message History**: `(conversation_id, inserted_at)` - Fast message retrieval
2. **Unread Counts**: Partial index on `conversation_participants` for unread detection
3. **User Lookups**: Index on `user_id` in participants table
4. **Moderation Queue**: Partial index on `flagged_at` WHERE not reviewed

### Query Optimization

1. **Pagination**: Default limit of 50 messages prevents loading entire history
2. **Preloading**: `Repo.preload([:sender, :participants])` to avoid N+1 queries
3. **Scoped Queries**: All queries scoped to current user's data only

### LiveView Streams

Use `stream/3` for efficient message list rendering:

```elixir
{:ok,
 socket
 |> stream(:messages, messages)}
```

Benefits:
- Only updates changed messages in DOM
- Efficient for real-time inserts
- Minimal re-rendering

## PubSub Architecture

### Topic Structure

**User-Level Topics**: `"user:#{user_id}:conversations"`
- Subscribe: When user enters conversation list
- Broadcast: When new message arrives in any conversation
- Use case: Update unread badges, refresh list

**Conversation-Level Topics**: `"conversation:#{conversation_id}"`
- Subscribe: When user opens specific conversation
- Broadcast: When message is sent in that conversation
- Use case: Real-time message delivery to all participants

### Broadcast Events

```elixir
# New message
{:new_message, %Message{}}

# Message updated (edited, hidden, flagged)
{:message_updated, %Message{}}

# Conversation metadata changed
{:conversation_updated, %Conversation{}}
```

### Example Flow

1. **User A sends message to User B**:
   ```elixir
   Messaging.send_message(scope_a, conversation_id, %{"body" => "Hello"})
   ```

2. **Context broadcasts to conversation topic**:
   ```elixir
   Phoenix.PubSub.broadcast(
     Homesite.PubSub,
     "conversation:#{conversation_id}",
     {:new_message, message}
   )
   ```

3. **Context broadcasts to User B's personal topic**:
   ```elixir
   Phoenix.PubSub.broadcast(
     Homesite.PubSub,
     "user:#{user_b_id}:conversations",
     {:new_message, message}
   )
   ```

4. **Both LiveViews handle the event**:
   - User B's conversation view: Inserts message in real-time
   - User B's conversation list: Updates unread badge

## Testing Strategy

### Unit Tests (`test/homesite/messaging_test.exs`)

**Context Functions**:
- Conversation creation (1-on-1)
- Duplicate prevention
- Message validation (length, spam)
- Blocking enforcement
- Soft delete behavior
- Read tracking
- Moderation queue

### Integration Tests (`test/homesite_web/live/conversation_live_test.exs`)

**LiveView Interactions**:
- Display conversation list
- Empty state ("No conversations yet")
- Send/receive messages in real-time
- Unread badges update
- Mark as read on view
- Hide message from UI
- Flag message for moderation
- Blocked user error handling

### Security Tests (`test/homesite_web/messaging_security_test.exs`)

**Cross-User Access**:
- Scope isolation for conversations
- Scope isolation for messages
- Scope isolation for blocking
- Spam keyword validation
- Self-blocking prevention

## Common Patterns

### Creating a Conversation

```elixir
# In LiveView
def handle_event("start_conversation", %{"user_id" => user_id}, socket) do
  case Messaging.create_conversation(socket.assigns.current_scope, user_id) do
    {:ok, conversation} ->
      {:noreply, push_navigate(socket, to: ~p"/conversations/#{conversation}")}

    {:error, :user_blocked} ->
      {:noreply, put_flash(socket, :error, "This user has blocked you")}

    {:error, changeset} ->
      {:noreply, assign(socket, form: to_form(changeset))}
  end
end
```

### Sending a Message

```elixir
# In LiveView
def handle_event("send_message", %{"body" => body}, socket) do
  case Messaging.send_message(
    socket.assigns.current_scope,
    socket.assigns.conversation.id,
    %{"body" => body}
  ) do
    {:ok, _message} ->
      # Message broadcasted automatically via PubSub
      form = to_form(%{"body" => ""})
      {:noreply, assign(socket, :form, form)}

    {:error, changeset} ->
      {:noreply, assign(socket, :form, to_form(changeset))}
  end
end

# Handle real-time broadcast
def handle_info({:new_message, message}, socket) do
  # Auto-scroll handled by JavaScript hook
  {:noreply, stream_insert(socket, :messages, message)}
end
```

### Handling Read Receipts

```elixir
# In mount/3
def mount(%{"id" => id}, _session, socket) do
  conversation = Messaging.get_conversation!(socket.assigns.current_scope, id)

  if connected?(socket) do
    Messaging.subscribe_conversation(socket.assigns.current_scope, id)
    Messaging.mark_as_read(socket.assigns.current_scope, id)
  end

  # ... rest of mount
end

# In handle_info (mark as read when viewing)
def handle_info({:new_message, message}, socket) do
  Messaging.mark_as_read(socket.assigns.current_scope, socket.assigns.conversation.id)
  {:noreply, stream_insert(socket, :messages, message)}
end
```

## Data Retention & Legal Compliance

### Message Permanence

**Policy**: All messages are permanent and never deleted from database.

**Reasoning**:
1. Legal/audit compliance
2. Dispute resolution
3. Moderation review
4. Pattern analysis for abuse detection

### Soft Delete (UI Only)

**Implementation**: `hidden_at` timestamp field

**Behavior**:
- Message hidden from UI for all users
- Message preserved in database
- Admins can still view in moderation queue
- Queryable for legal requests

**User Communication**:
- "Hide" button tooltip: "This hides the message from view but preserves it for legal/audit purposes"

### GDPR Considerations

**User Data Deletion Requests**:
1. Anonymize user_id in messages (replace with "Deleted User")
2. Retain message content (legal requirement)
3. Remove from sender/recipient fields but preserve thread
4. Block deletion of flagged messages under review

**Implementation** (future):
```elixir
def anonymize_user_messages(user_id) do
  from(m in Message, where: m.sender_id == ^user_id)
  |> Repo.update_all(set: [
    sender_id: nil,
    anonymized_at: DateTime.utc_now(:second)
  ])
end
```

## Monitoring & Alerts

### Metrics to Track

1. **Message Volume**: Messages sent per hour/day
2. **Spam Detection Rate**: % of messages rejected for spam
3. **Flagged Messages**: Count in moderation queue
4. **Block Rate**: New blocks per day
5. **Rate Limit Violations**: Users hitting rate limits

### Recommended Alerts

1. **Spam Wave**: >100 flagged messages in 1 hour
2. **Bot Detection**: Single user hitting rate limit repeatedly
3. **Moderation Queue**: >50 pending reviews
4. **Abuse Pattern**: Same user flagged by 5+ different users

### Implementation

```elixir
# In Messaging context
defp log_metric(metric, value) do
  :telemetry.execute(
    [:homesite, :messaging, metric],
    %{value: value},
    %{}
  )
end

# In send_message/3
def send_message(%Scope{} = scope, conversation_id, attrs) do
  with {:ok, message} <- create_message(attrs) do
    log_metric(:message_sent, 1)
    broadcast_message(message)
    {:ok, message}
  end
end
```

## Future Enhancements

### Phase 2: Group Conversations

**Changes Required**:
1. Update `create_conversation/3` to accept multiple user IDs
2. Add `add_participant/3` and `remove_participant/3` functions
3. Add role field to `conversation_participants` (owner/member)
4. Group naming/avatars
5. Permissions (who can invite, remove, etc.)

**Estimated Effort**: 20-30 hours

### Phase 3: Advanced Features

**Possible Features**:
- Message search (full-text index)
- File attachments (Arc/Waffle + S3)
- Typing indicators (PubSub with ephemeral state)
- Message reactions (separate `message_reactions` table)
- Push notifications (email/browser)
- Message threads (reply-to functionality)
- Voice messages (audio upload + transcription)
- Message forwarding
- Conversation archiving

**Estimated Effort**: 40-60 hours total

## Troubleshooting

### Common Issues

**1. Messages not appearing in real-time**
- Check PubSub subscription in `mount/3` with `connected?(socket)`
- Verify `handle_info({:new_message, _})` callback exists
- Check browser console for WebSocket errors

**2. "Not a participant" errors**
- Verify `is_participant?/2` check passes
- Check conversation_participants table has correct entries
- Ensure scope.user.id matches participant user_id

**3. Spam filter too aggressive**
- Review spam_keywords list
- Consider fuzzy matching vs exact matching
- Add configuration for custom keyword lists

**4. Rate limiting blocking legitimate users**
- Increase limit from 50/min to 100/min
- Add user-specific rate limits (premium users)
- Implement exponential backoff in UI

### Debug Helpers

```elixir
# Check if user is participant
iex> Messaging.is_participant?(scope, conversation_id)
true

# List all conversations for debugging
iex> Messaging.list_conversations(scope)
[%{conversation: %Conversation{}, unread_count: 3, ...}]

# Check blocking status
iex> Messaging.is_blocked?(scope, other_user_id)
false

# View moderation queue
iex> Messaging.list_flagged_messages(admin_scope)
[%Message{flagged_at: ~U[...], flagged_reason: "spam"}, ...]
```

## Configuration

### Environment Variables

```elixir
# config/runtime.exs (future)
config :homesite, Homesite.Messaging,
  rate_limit_per_minute: System.get_env("MESSAGING_RATE_LIMIT", "50") |> String.to_integer(),
  max_message_length: System.get_env("MESSAGING_MAX_LENGTH", "5000") |> String.to_integer(),
  spam_keywords: String.split(System.get_env("MESSAGING_SPAM_KEYWORDS", ""), ",")
```

### Feature Flags (future)

```elixir
config :homesite, :features,
  messaging_enabled: true,
  messaging_groups_enabled: false,  # Phase 2
  messaging_attachments_enabled: false  # Phase 3
```

## API Documentation

Complete function documentation with examples is available in:
- Context: `lib/homesite/messaging.ex` (@doc blocks)
- Schemas: `lib/homesite/messaging/*.ex` (@moduledoc blocks)

## Support & Maintenance

### Code Owners
- **Primary**: Backend team
- **LiveView UI**: Frontend team
- **Security**: Security team

### Regular Maintenance Tasks
1. **Weekly**: Review moderation queue
2. **Monthly**: Analyze spam detection effectiveness
3. **Quarterly**: Review blocked user patterns
4. **Yearly**: Audit message retention policy compliance

---

**Last Updated**: 2025-12-04
**Version**: 1.0 (Phase 1 - 1-on-1 Messaging)
**Status**: Implementation Ready
