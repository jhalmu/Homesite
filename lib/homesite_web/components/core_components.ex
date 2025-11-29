defmodule HomesiteWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: HomesiteWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      phx-hook="AutoDismissFlash"
      role="alert"
      class="toast toast-top toast-center z-50"
      {@rest}
    >
      <div class={[
        "alert max-w-80 text-wrap w-80 sm:max-w-96 sm:w-96",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group cursor-pointer self-start" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :string
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}

    assigns =
      assign_new(assigns, :class, fn ->
        ["btn", Map.fetch!(variants, assigns[:variant])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :string, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :help, doc: "the help text shown alongside the input"

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class={["field-with-help", @help == [] && "mb-2"]}>
      <div class="field-input">
        <div class="fieldset">
          <label>
            <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
            <span class="label">
              <input
                type="checkbox"
                id={@id}
                name={@name}
                value="true"
                checked={@checked}
                class={@class || "checkbox checkbox-sm"}
                {@rest}
              />{@label}
            </span>
          </label>
          <.error :for={msg <- @errors}>{msg}</.error>
        </div>
      </div>
      <div :if={@help != []} class="field-help">
        <div class="bg-base-200/50 rounded-lg p-4 text-sm">
          <div class="flex items-start gap-2">
            <.icon name="hero-information-circle" class="text-info mt-0.5 h-5 w-5 flex-shrink-0" />
            <div class="text-base-content/70">
              {render_slot(@help)}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class={["field-with-help", @help == [] && "mb-2"]}>
      <div class="field-input">
        <div class="fieldset">
          <label>
            <span :if={@label} class="label mb-1">{@label}</span>
            <select
              id={@id}
              name={@name}
              class={[@class || "select w-full", @errors != [] && (@error_class || "select-error")]}
              multiple={@multiple}
              {@rest}
            >
              <option :if={@prompt} value="">{@prompt}</option>
              {Phoenix.HTML.Form.options_for_select(@options, @value)}
            </select>
          </label>
          <.error :for={msg <- @errors}>{msg}</.error>
        </div>
      </div>
      <div :if={@help != []} class="field-help">
        <div class="bg-base-200/50 rounded-lg p-4 text-sm">
          <div class="flex items-start gap-2">
            <.icon name="hero-information-circle" class="text-info mt-0.5 h-5 w-5 flex-shrink-0" />
            <div class="text-base-content/70">
              {render_slot(@help)}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class={["field-with-help", @help == [] && "mb-2"]}>
      <div class="field-input">
        <div class="fieldset">
          <label>
            <span :if={@label} class="label mb-1">{@label}</span>
            <textarea
              id={@id}
              name={@name}
              class={[
                @class || "textarea w-full",
                @errors != [] && (@error_class || "textarea-error")
              ]}
              {@rest}
            >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
          </label>
          <.error :for={msg <- @errors}>{msg}</.error>
        </div>
      </div>
      <div :if={@help != []} class="field-help">
        <div class="bg-base-200/50 rounded-lg p-4 text-sm">
          <div class="flex items-start gap-2">
            <.icon name="hero-information-circle" class="text-info mt-0.5 h-5 w-5 flex-shrink-0" />
            <div class="text-base-content/70">
              {render_slot(@help)}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class={["field-with-help", @help == [] && "mb-2"]}>
      <div class="field-input">
        <div class="fieldset">
          <label>
            <span :if={@label} class="label mb-1">{@label}</span>
            <input
              type={@type}
              name={@name}
              id={@id}
              value={Phoenix.HTML.Form.normalize_value(@type, @value)}
              class={[@class || "input w-full", @errors != [] && (@error_class || "input-error")]}
              {@rest}
            />
          </label>
          <.error :for={msg <- @errors}>{msg}</.error>
        </div>
      </div>
      <div :if={@help != []} class="field-help">
        <div class="bg-base-200/50 rounded-lg p-4 text-sm">
          <div class="flex items-start gap-2">
            <.icon name="hero-information-circle" class="text-info mt-0.5 h-5 w-5 flex-shrink-0" />
            <div class="text-base-content/70">
              {render_slot(@help)}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="text-error mt-1.5 flex items-center gap-2 text-sm">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-base-content/70 text-sm">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table-zebra table">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Renders a user avatar.

  Displays an uploaded avatar or generates an SVG avatar with user initials.
  Uses fluid sizing for responsive design.

  ## Examples

      <.avatar user={@user} />
      <.avatar user={@user} class="w-12 h-12" />
  """
  attr :user, :map, required: true, doc: "the user struct"
  attr :class, :string, default: nil, doc: "additional CSS classes"
  attr :rest, :global, doc: "arbitrary HTML attributes"

  def avatar(assigns) do
    assigns = assign(assigns, :avatar_url, Homesite.Accounts.get_avatar_url(assigns.user))

    ~H"""
    <img
      src={@avatar_url}
      alt={"#{@user.display_name || @user.email} avatar"}
      class={[
        "rounded-full object-cover",
        if(@class, do: @class, else: "w-[clamp(2rem,8vw,3rem)] h-[clamp(2rem,8vw,3rem)]")
      ]}
      {@rest}
    />
    """
  end

  @doc """
  Renders an author byline with avatar, name, and optional date.

  Displays user information in a consistent format across the application.
  Uses fluid typography and spacing from MODERN_CSS_GUIDE.md patterns.
  Dates are formatted using JavaScript based on user's locale preference.

  ## Examples

      <.author_byline user={@user} />
      <.author_byline user={@user} date={@post.published_at} />
      <.author_byline user={@user} date={@post.published_at} current_scope={@current_scope} />
      <.author_byline user={@user} date={@post.published_at} relative={true} />
  """
  attr :user, :map, required: true, doc: "the user struct"
  attr :date, :any, default: nil, doc: "optional datetime to display"
  attr :current_scope, :map, default: nil, doc: "current scope for locale preference"
  attr :relative, :boolean, default: false, doc: "show relative time (e.g., '2 hours ago')"
  attr :class, :string, default: nil, doc: "additional CSS classes"
  attr :rest, :global, doc: "arbitrary HTML attributes"

  def author_byline(assigns) do
    # Get user's preferred locale, fallback to current Gettext locale
    locale =
      get_in(assigns, [:current_scope, :user, :preferred_language]) ||
        Gettext.get_locale(HomesiteWeb.Gettext)

    assigns = assign(assigns, :locale, locale)

    ~H"""
    <div class={["gap-[clamp(0.5rem,2vw,1rem)] flex items-center", @class]} {@rest}>
      <.avatar user={@user} class="h-10 w-10" />
      <div class="flex flex-col">
        <span class="text-[clamp(0.875rem,2vw,1rem)] font-medium">
          {@user.display_name || String.split(@user.email, "@") |> List.first()}
        </span>
        <time
          :if={@date}
          class="text-sm text-gray-600 dark:text-gray-400"
          datetime={DateTime.to_iso8601(@date)}
          phx-hook="LocalTime"
          data-locale={@locale}
          data-relative={to_string(@relative)}
          id={"time-#{System.unique_integer([:positive])}"}
        >
          {Calendar.strftime(@date, "%B %d, %Y")}
        </time>
      </div>
    </div>
    """
  end

  @doc """
  Renders the Pegasus logo SVG.

  A reusable component for the site's Pegasus branding.
  Can be used in headers, footers, and anywhere the logo is needed.

  ## Examples

      <.pegasus class="h-12 w-12" />
      <.pegasus class="h-36 w-28" />
  """
  attr :class, :string, default: "h-12 w-12", doc: "CSS classes for sizing"
  attr :fill, :string, default: "#ff4500", doc: "SVG fill color"
  attr :rest, :global, doc: "arbitrary HTML attributes"

  def pegasus(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 -20 100 140"
      class={@class}
      fill={@fill}
      {@rest}
    >
      <g transform="scale(-1, 1) translate(-100, 5)">
        <!-- Horse body -->
        <ellipse cx="55" cy="60" rx="22" ry="16" />
        
    <!-- Horse neck -->
        <path
          d="M 40 55 Q 32 50 28 42"
          stroke={@fill}
          stroke-width="8"
          fill="none"
          stroke-linecap="round"
        />
        
    <!-- Horse head (elongated, horizontal) -->
        <ellipse cx="22" cy="38" rx="8" ry="5.5" />
        
    <!-- Snout/muzzle -->
        <ellipse cx="15" cy="38" rx="3.5" ry="3" />
        
    <!-- Ear (pointed upward) -->
        <path d="M 26 32 L 28 26 L 24 30 Z" />
        
    <!-- HORN - Majestic unicorn/pegasus horn -->
        <path d="M 24 30 L 22 18 L 26 28 Z" fill="#FFD700" opacity="0.9" />
        <path d="M 23 28 L 22 18" stroke="#FFA500" stroke-width="0.5" fill="none" />
        
    <!-- Eye -->
        <circle cx="24" cy="37" r="1.5" fill="white" />
        <circle cx="24" cy="37" r="0.8" fill="#333" />
        
    <!-- Nostril -->
        <circle cx="15" cy="39" r="0.7" fill="#cc3300" opacity="0.6" />
        
    <!-- Front legs -->
        <rect x="42" y="68" width="4" height="20" rx="2" />
        <rect x="48" y="68" width="4" height="20" rx="2" />
        
    <!-- Back legs -->
        <rect x="62" y="68" width="4" height="20" rx="2" />
        <rect x="68" y="68" width="4" height="20" rx="2" />
        
    <!-- Tail - flowing -->
        <path
          d="M 75 58 Q 82 55 85 60 Q 84 65 80 68"
          stroke={@fill}
          stroke-width="3"
          fill="none"
          stroke-linecap="round"
        />
        
    <!-- Mane - flowing -->
        <path
          d="M 28 38 Q 32 34 36 38"
          stroke={@fill}
          stroke-width="2.5"
          fill="none"
          stroke-linecap="round"
        />
        <path
          d="M 32 42 Q 36 38 40 42"
          stroke={@fill}
          stroke-width="2.5"
          fill="none"
          stroke-linecap="round"
        />
        <path
          d="M 36 46 Q 40 42 44 46"
          stroke={@fill}
          stroke-width="2.5"
          fill="none"
          stroke-linecap="round"
        />
        
    <!-- WINGS - Larger, more majestic wings -->
        <!-- Upper wing layer -->
        <path
          d="M 58 48 Q 70 38 82 40 Q 88 42 90 48 Q 88 56 82 62 Q 74 66 66 64 Q 60 60 58 52 Z"
          opacity="0.95"
          stroke={@fill}
          stroke-width="0.5"
        />
        <!-- Middle wing layer -->
        <path
          d="M 59 52 Q 68 44 78 46 Q 84 48 86 54 Q 84 60 78 64 Q 72 66 66 63 Q 61 59 59 54 Z"
          opacity="0.85"
        />
        <!-- Lower wing layer -->
        <path
          d="M 60 55 Q 66 50 74 52 Q 78 54 80 58 Q 78 62 74 64 Q 70 64 66 62 Q 62 59 60 56 Z"
          opacity="0.75"
        />
        <!-- Wing detail lines (feathers) -->
        <path d="M 62 50 Q 70 46 76 48" stroke={@fill} stroke-width="0.5" fill="none" opacity="0.6" />
        <path d="M 64 54 Q 70 50 76 52" stroke={@fill} stroke-width="0.5" fill="none" opacity="0.6" />
        <path d="M 66 58 Q 70 54 74 56" stroke={@fill} stroke-width="0.5" fill="none" opacity="0.6" />
      </g>
    </svg>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(HomesiteWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(HomesiteWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Renders a statistics card for analytics dashboard.

  ## Examples

      <.stat_card title="Total Users" value={150} icon="hero-users" color="bg-blue-100 text-blue-800" />
  """
  attr :title, :string, required: true
  attr :value, :any, required: true
  attr :icon, :string, default: "hero-chart-bar"
  attr :color, :string, default: "bg-gray-100 text-gray-800"

  def stat_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm border border-base-300">
      <div class="card-body">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-base-content/60"><%= @title %></p>
            <p class="text-3xl font-bold mt-1"><%= @value %></p>
          </div>
          <div class={"rounded-full p-3 #{@color}"}>
            <.icon name={@icon} class="h-6 w-6" />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
