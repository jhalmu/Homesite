# Monetization Plan - Homesite Platform

**Status:** Draft
**Last Updated:** 2025-11-28
**Compliance:** Finnish Fundraising Law (863/2019) compliant

## Legal Framework (Finland)

### Key Requirements
Per Finnish fundraising law (863/2019), we **cannot** accept donations without providing tangible value in return. All monetization must be based on **compensated transactions** where customers receive clear benefits.

### Permitted Models
✅ **Service-based pricing** - Customers pay for features/services
✅ **Tiered subscriptions** - Clear feature differences per tier
✅ **Commercial sales** - Selling plugins, themes, premium features
✅ **Support contracts** - Technical assistance, consulting
✅ **Sponsorship agreements** - Formal contracts with businesses

### Prohibited Models
❌ Donation-based funding (Patreon, Open Collective without benefits)
❌ "Pay what you want" for free software
❌ Voluntary contributions without tangible return
❌ Crowdfunding without clear deliverables

## Target Audience

### Primary: Personal Tech Bloggers & Portfolio Sites
- Developers, designers, writers
- Want professional presence with RSS aggregation
- Comfortable with self-hosting or managed hosting
- Value: Custom domain, feed curation, professional appearance

### Secondary: Small Tech Communities
- Dev groups, tech clubs, study groups
- Need multi-user blogging platform
- Value: Collaboration, feed sharing, discussions

### Tertiary: Professional Portfolios
- Consultants, freelancers
- Want to showcase work + curated industry feeds
- Value: Professional appearance, SEO, credibility

## Free Tier (Self-Hosted)

### Features
✅ Full source code (MIT/Apache 2.0 license)
✅ Unlimited posts and users (self-hosted)
✅ Up to 5 RSS/Atom feed sources per user
✅ Basic feed refresh (every 2 hours)
✅ Standard themes
✅ Community support (GitHub issues)

### Limitations
- Self-hosting required (users manage infrastructure)
- Community support only (no SLA)
- Standard refresh intervals
- No premium features

### Rationale
- Provides value to open source community
- Builds user base and reputation
- Creates upgrade path to managed service
- Complies with Finnish law (no donation solicitation)

## Paid Tier 1: Managed Hosting (€9.90/month)

### What Customer Gets
✅ **Fully managed hosting** (no DevOps needed)
✅ Custom domain support
✅ Up to 20 RSS/Atom feed sources per user
✅ Fast feed refresh (every 15 minutes)
✅ 10 GB storage
✅ Email support (48h response SLA)
✅ Automatic backups (daily)
✅ SSL certificates included
✅ 99% uptime guarantee

### Cost Structure
- Server hosting: €5/month (DigitalOcean/Hetzner)
- Bandwidth: €1/month (estimated)
- Support overhead: €2/month
- Margin: €1.90/month
- Break-even: ~100 users

### Target: Personal bloggers who want hassle-free hosting

## Paid Tier 2: Professional (€19.90/month)

### What Customer Gets
Everything in Managed Hosting, plus:
✅ **Unlimited RSS/Atom feed sources**
✅ Bluesky & Mastodon feed integration (when available)
✅ Fast refresh (every 5 minutes)
✅ 50 GB storage
✅ Priority email support (24h response SLA)
✅ Custom themes and styling
✅ Advanced analytics dashboard
✅ Export all data (JSON, CSV)
✅ API access for integrations

### Cost Structure
- Enhanced server: €10/month
- API costs (Bluesky/Mastodon): €2/month
- Priority support: €4/month
- Margin: €3.90/month
- Break-even: ~50 users

### Target: Professional bloggers, consultants, power users

## Paid Tier 3: Team (€49.90/month)

### What Customer Gets
Everything in Professional, plus:
✅ **Up to 10 user accounts**
✅ Shared feed libraries
✅ Collaborative content management
✅ Advanced role-based permissions
✅ 200 GB storage
✅ Phone/chat support (12h response SLA)
✅ Custom onboarding session
✅ Quarterly strategy calls

### Cost Structure
- Dedicated server resources: €25/month
- Premium support: €15/month
- Margin: €9.90/month
- Break-even: ~25 teams

### Target: Small tech teams, dev communities, agencies

## Alternative Revenue: Service Contracts

### Custom Development (€80-120/hour)
- Feature development for specific needs
- Custom integrations (APIs, webhooks)
- Theme customization
- Migration assistance

### Consulting Services (€100-150/hour)
- RSS strategy consulting
- Content curation best practices
- SEO optimization
- Feed discovery and setup

### Support Contracts (€200-500/month)
- Dedicated support for organizations
- Custom SLA agreements
- Priority bug fixes
- Feature requests

**Rationale:** Provides direct value for payment, fully compliant with Finnish law

## Implementation Roadmap

### Phase 1: Open Source Foundation (Current)
**Timeline:** Q4 2025
- ✅ Complete core features (RSS/Atom feeds)
- ⏳ LiveView UI (Phase 6)
- ⏳ Public instance for testing
- ⏳ Documentation and guides

### Phase 2: Managed Hosting Beta (Q1 2026)
**Timeline:** January-March 2026
- Payment integration (Stripe)
- User management dashboard
- Automated deployment pipeline
- Backup and restore system
- Initial pricing: €7.90/month (beta discount)

### Phase 3: Professional Tier (Q2 2026)
**Timeline:** April-June 2026
- Bluesky & Mastodon adapters
- Advanced analytics
- Custom themes
- API access
- Pricing: €19.90/month

### Phase 4: Team Features (Q3 2026)
**Timeline:** July-September 2026
- Multi-user collaboration
- Role-based permissions
- Shared feed libraries
- Advanced reporting
- Pricing: €49.90/month

## Cost Analysis

### Infrastructure Costs (per tier)

**Free Tier (self-hosted):**
- Cost to us: €0 (users host themselves)
- Support cost: ~€2/month/user (community forum)

**Managed Hosting (€9.90/month):**
- Server: €5/month
- Bandwidth: €1/month
- Backups: €1/month
- Support: €2/month
- **Total: €9/month** (€0.90 margin)

**Professional (€19.90/month):**
- Enhanced server: €10/month
- API costs: €2/month
- Bandwidth: €2/month
- Backups: €2/month
- Support: €4/month
- **Total: €20/month** (€-0.10 margin initially, improves with scale)

**Team (€49.90/month):**
- Dedicated resources: €25/month
- API costs: €5/month
- Bandwidth: €3/month
- Backups: €3/month
- Support: €15/month
- **Total: €51/month** (€-1.10 margin initially, improves with scale)

### Revenue Projections (Year 1)

**Conservative Estimate:**
- Free users: 500 (marketing/community)
- Managed Hosting: 50 users × €9.90 = €495/month
- Professional: 10 users × €19.90 = €199/month
- Team: 2 teams × €49.90 = €99.80/month
- **Total: €793.80/month (€9,525.60/year)**

**Optimistic Estimate:**
- Free users: 2,000
- Managed Hosting: 200 users × €9.90 = €1,980/month
- Professional: 50 users × €19.90 = €995/month
- Team: 10 teams × €49.90 = €499/month
- **Total: €3,474/month (€41,688/year)**

### Break-Even Analysis

**Fixed Costs:**
- Infrastructure: €100/month (shared hosting)
- Tools (Stripe, monitoring): €50/month
- Development time: €0 (solo developer)
- **Total: €150/month**

**Break-even:** 20 Managed Hosting users OR 10 Professional users OR 4 Team subscriptions

## Competitive Analysis

### Similar Platforms

**Ghost (ghost.org):**
- Pricing: $9-299/month
- Focus: Professional publishing
- Our advantage: RSS aggregation, multi-user from start

**Substack:**
- Free with 10% fee on paid newsletters
- Focus: Newsletter monetization
- Our advantage: More control, feed curation

**WordPress.com:**
- Pricing: $4-45/month
- Focus: General blogging
- Our advantage: Feed aggregation, modern tech stack

**Micro.blog:**
- Pricing: $5/month
- Focus: Microblogging, IndieWeb
- Our advantage: Longer-form content, feed curation

### Unique Value Proposition

1. **RSS/Atom Feed Aggregation** - Built-in, not a plugin
2. **Multi-user from the start** - Designed for collaboration
3. **Modern tech stack** - Phoenix LiveView, real-time updates
4. **Open source** - Full transparency, self-hosting option
5. **Privacy-focused** - No tracking, no ads, user data ownership

## Legal Compliance

### Finnish Law Compliance
✅ All tiers provide **tangible services** for payment
✅ Clear **value proposition** for each tier
✅ No donation solicitation
✅ Formal service agreements with receipts
✅ Market-rate pricing with documented features

### Required Documentation
- Terms of Service
- Privacy Policy
- Service Level Agreements (SLAs)
- Refund policy (14-day EU requirement)
- Data processing agreements (GDPR)

### Payment Processing
- Stripe (Finnish business account)
- Proper invoicing and receipts
- VAT compliance (24% in Finland)
- Currency: EUR (primary), USD (secondary)

## Marketing Strategy

### Free Tier (Community Building)
- GitHub presence (stars, forks)
- Dev.to articles and tutorials
- Reddit (r/selfhosted, r/elixir)
- Hacker News launches
- Open source communities

### Paid Tiers (Value Communication)
- Focus on **time savings** (no DevOps)
- Highlight **managed infrastructure**
- Emphasize **support and reliability**
- Showcase customer success stories
- Professional appearance and SEO benefits

### Content Marketing
- Blog about RSS/feed curation
- Tutorials on content discovery
- Case studies from beta users
- Technical deep-dives (Phoenix, Elixir)

## Risk Mitigation

### Legal Risks
- Regular legal review of terms
- Clear service descriptions
- Avoid donation language entirely
- Document all customer interactions

### Technical Risks
- Multiple server providers (avoid lock-in)
- Automated backups (daily)
- Monitoring and alerting
- Staged rollouts for changes

### Financial Risks
- Start with small server commitments
- Scale infrastructure with revenue
- 3-month cash reserve for operations
- Conservative user projections

## Success Metrics

### Year 1 Goals
- 500+ free tier users (self-hosted)
- 50+ paid subscribers (any tier)
- €500/month recurring revenue
- 95%+ customer satisfaction
- <5% monthly churn rate

### Year 2 Goals
- 2,000+ free tier users
- 200+ paid subscribers
- €2,000/month recurring revenue
- 97%+ customer satisfaction
- <3% monthly churn rate

### Year 3 Goals
- 5,000+ free tier users
- 500+ paid subscribers
- €5,000/month recurring revenue
- Sustainable full-time development
- Product-market fit validated

## Next Steps

### Immediate (Q4 2025)
1. ✅ Complete External Feeds Phase 6 (LiveView UI)
2. Complete Phase 7 (Polish and optimization)
3. Deploy public demo instance
4. Create landing page with pricing

### Short-term (Q1 2026)
1. Implement Stripe integration
2. Build user management dashboard
3. Create signup flow
4. Launch beta program (€7.90/month)
5. Gather feedback from first 20 customers

### Medium-term (Q2-Q3 2026)
1. Add Professional tier features
2. Implement Bluesky/Mastodon adapters
3. Build analytics dashboard
4. Launch Team tier
5. Achieve break-even (€150/month revenue)

## Conclusion

This monetization plan is **Finnish law compliant** by focusing on compensated transactions where customers receive clear, tangible benefits. The tiered approach allows users to self-host for free while providing paid options for those who value managed hosting, premium features, and professional support.

**Key Principles:**
- Provide real value for every euro charged
- Never solicit donations
- Clear service descriptions
- Market-rate pricing
- Professional service delivery

**Target:** €500/month revenue by end of Year 1, scaling to €2,000/month by Year 2.
