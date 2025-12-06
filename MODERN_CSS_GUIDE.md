# Modern CSS - Homesite Projektin Ohje

## Käyttö DaisyUI + Tailwindin kanssa

### 1. Fluid Typography & Spacing

```heex
<!-- Blog post card -->
<div class="card bg-base-100 shadow-xl w-[min(90vw,800px)]">
  <div class="card-body p-[clamp(1rem,3vw,2rem)]">
    <h2 class="card-title text-[clamp(1.25rem,3vw,2rem)]">
      <%= @post.title %>
    </h2>
    
    <p class="text-[clamp(0.875rem,1.5vw,1rem)] text-base-content/70">
      <%= @post.excerpt %>
    </p>
    
    <!-- Tag badges with responsive gaps -->
    <div class="card-actions gap-[clamp(0.25rem,1vw,0.5rem)]">
      <%= for tag <- @post.tags do %>
        <span class="badge badge-primary"><%= tag.name %></span>
      <% end %>
    </div>
  </div>
</div>
```

### 2. Responsive Grid Layout

```heex
<!-- Post-listaus joka mukautuu automaattisesti -->
<div class="grid gap-[clamp(1rem,3vw,2rem)] w-[min(95vw,1400px)] mx-auto"
     style="grid-template-columns: repeat(auto-fit, minmax(min(100%, 300px), 1fr));">
  <%= for post <- @posts do %>
    <article class="card bg-base-200">
      <!-- post content -->
    </article>
  <% end %>
</div>
```

**Selitys:**
- `auto-fit` = Täyttää tilan automaattisesti
- `minmax(min(100%, 300px), 1fr)` = Vähintään 300px, mutta kapeilla ruuduilla 100%
- Ei tarvitse media queryjä!

### 3. Container Layout (app.css)

```css
/* assets/css/app.css */
:root {
  /* Layoutit */
  --content-max-width: min(95vw, 1400px);
  --article-max-width: min(90vw, 800px);
  --sidebar-width: max(250px, 20vw);
  
  /* Typography */
  --fluid-text-base: clamp(1rem, 2vw, 1.25rem);
  --fluid-text-lg: clamp(1.125rem, 2.5vw, 1.5rem);
  --fluid-text-xl: clamp(1.25rem, 3vw, 2rem);
  
  /* Spacing */
  --card-padding: clamp(1rem, 3vw, 2rem);
  --section-gap: clamp(2rem, 5vw, 4rem);
  --inline-gap: clamp(0.25rem, 1vw, 0.5rem);
}

/* Käytä näitä komponenteissa */
.content-container {
  width: var(--content-max-width);
  margin: 0 auto;
  padding: var(--card-padding);
}

.article-body {
  width: var(--article-max-width);
  margin: 0 auto;
  font-size: var(--fluid-text-base);
  line-height: 1.6;
}
```

### 4. Container Query - Post Cards

**✅ IMPLEMENTED** (2025-12-06)

Container queries are now active for all `.post-card` and `.listing-card` elements. Cards automatically adjust their layout based on container width, not viewport width.

```css
/* Post-kortit mukautuvat omaan tilaansa (assets/css/app.css) */
.post-card,
.listing-card {
  container-type: inline-size;
}

/* Small containers (< 500px): Compact layout */
@container (max-width: 500px) {
  .post-card,
  .listing-card {
    padding: var(--space-sm);
  }

  .post-card .card-actions,
  .listing-card .card-actions {
    flex-direction: column;
    align-items: flex-start;
  }

  .post-title,
  .listing-title {
    font-size: var(--text-lg);
  }
}

/* Medium containers (501px - 700px): Balanced layout */
@container (min-width: 501px) and (max-width: 700px) {
  .post-card,
  .listing-card {
    padding: var(--space-md);
  }
}

/* Large containers (> 700px): Spacious layout */
@container (min-width: 701px) {
  .post-card,
  .listing-card {
    padding: var(--space-lg);
  }
}
```

**Usage in Templates:**

Add `.post-card` or `.listing-card` class to enable responsive behavior:

```heex
<!-- Post cards in search results -->
<article class="post-card card bg-base-100 shadow-md">
  <div class="card-body">
    <h3 class="card-title">{@post.title}</h3>
  </div>
</article>

<!-- Feed items -->
<article class="listing-card card bg-base-200">
  <div class="card-body">
    <h3 class="card-title">{@item.title}</h3>
  </div>
</article>
```

**Benefits:**
- Cards in sidebars stay compact even on wide screens
- Cards in grid layouts adapt to column width, not viewport
- No JavaScript or media queries needed
- Truly modular components

**Browser Support:** Chrome 105+, Firefox 110+, Safari 16+ (Sept 2022+)

### 5. Forms & Inputs

```heex
<!-- Login/Register form -->
<div class="card w-[min(90vw,500px)] bg-base-100 shadow-xl">
  <div class="card-body p-[clamp(1.5rem,4vw,3rem)]">
    <h2 class="card-title text-[clamp(1.5rem,3vw,2rem)]">Kirjaudu</h2>
    
    <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
      <.input 
        field={@form[:email]} 
        type="email" 
        label="Sähköposti" 
        required 
        class="input input-bordered w-full text-[clamp(0.875rem,1.5vw,1rem)]"
      />
      
      <.input 
        field={@form[:password]} 
        type="password" 
        label="Salasana" 
        required 
        class="input input-bordered w-full"
      />
      
      <div class="mt-[clamp(1rem,2vw,1.5rem)]">
        <button class="btn btn-primary w-full">Kirjaudu</button>
      </div>
    </.simple_form>
  </div>
</div>
```

### 6. Navbar Responsiivisuus

```heex
<div class="navbar bg-base-100 px-[clamp(1rem,5vw,4rem)] min-h-[max(4rem,10vh)]">
  <div class="navbar-start">
    <.link navigate={~p"/"} class="btn btn-ghost text-[clamp(1rem,2.5vw,1.5rem)]">
      Homesite
    </.link>
  </div>
  
  <div class="navbar-end gap-[clamp(0.5rem,2vw,1rem)]">
    <%= if @current_user do %>
      <.link navigate={~p"/posts"} class="btn btn-ghost">
        Postit
      </.link>
      <.link navigate={~p"/users/settings"} class="btn btn-ghost">
        Asetukset
      </.link>
    <% else %>
      <.link navigate={~p"/users/register"} class="btn btn-ghost">
        Rekisteröidy
      </.link>
      <.link navigate={~p"/users/log_in"} class="btn btn-primary">
        Kirjaudu
      </.link>
    <% end %>
  </div>
</div>
```

### 7. Sidebar Layout

```heex
<!-- Sidebar + Main content -->
<div class="flex gap-[clamp(1rem,3vw,2rem)] w-[min(95vw,1400px)] mx-auto"
     style="flex-direction: row; flex-wrap: wrap;">
  
  <!-- Sidebar -->
  <aside class="w-[max(250px,20vw)] min-w-[250px] flex-shrink-0">
    <div class="card bg-base-200">
      <div class="card-body p-[clamp(1rem,2vw,1.5rem)]">
        <h3 class="card-title text-[clamp(1rem,2vw,1.25rem)]">Tagit</h3>
        <div class="flex flex-wrap gap-2">
          <%= for tag <- @tags do %>
            <.link navigate={~p"/posts?tag=#{tag.id}"} class="badge badge-outline">
              <%= tag.name %>
            </.link>
          <% end %>
        </div>
      </div>
    </div>
  </aside>
  
  <!-- Main content -->
  <main class="flex-1 min-w-[min(100%,500px)]">
    <%= @inner_content %>
  </main>
</div>
```

### 8. Responsive Images

```heex
<!-- Kuva joka skaalautuu kortissa -->
<figure class="w-full h-[clamp(200px,30vw,400px)] overflow-hidden">
  <img 
    src={@post.image_url} 
    alt={@post.title}
    class="w-full h-full object-cover"
  />
</figure>
```

### 9. Tag Cloud - Advanced

```css
/* assets/css/app.css */
.tag-cloud {
  container-type: inline-size;
  display: flex;
  flex-wrap: wrap;
  gap: clamp(0.25rem, 1vw, 0.5rem);
}

@container (max-width: 300px) {
  .tag-cloud .badge {
    font-size: 0.75rem;
    padding: 0.25rem 0.5rem;
  }
}
```

```heex
<div class="tag-cloud">
  <%= for tag <- @post.tags do %>
    <span class="badge badge-primary"><%= tag.name %></span>
  <% end %>
</div>
```

### 10. Table Layout

```heex
<!-- Admin-paneeli: Posts-listaus -->
<div class="overflow-x-auto w-[min(95vw,1400px)] mx-auto">
  <table class="table table-zebra w-full text-[clamp(0.875rem,1.5vw,1rem)]">
    <thead>
      <tr>
        <th>Otsikko</th>
        <th class="hidden sm:table-cell">Tagit</th>
        <th class="hidden md:table-cell">Luotu</th>
        <th>Toiminnot</th>
      </tr>
    </thead>
    <tbody>
      <%= for post <- @posts do %>
        <tr>
          <td class="font-medium"><%= post.title %></td>
          <td class="hidden sm:table-cell">
            <%= Enum.map_join(post.tags, ", ", & &1.name) %>
          </td>
          <td class="hidden md:table-cell">
            <%= Calendar.strftime(post.inserted_at, "%d.%m.%Y") %>
          </td>
          <td>
            <.link navigate={~p"/posts/#{post}"} class="btn btn-ghost btn-sm">
              Näytä
            </.link>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

## Käytännön Muistisäännöt

### DaisyUI + Modern CSS

- **DaisyUI** = Komponentit, teemat, värit
- **clamp()** = Tekstikoot, padding, margin
- **min()** = Maksimileveydet (estä liian leveä sisältö)
- **max()** = Minimileevydet (estä liian kapea sidebar)
- **Container queries** = Komponenttien sisäinen responsiivisuus
- **CSS custom properties** = Toistuvat arvot yhteen paikkaan

### Suositellut Arvot Homesitelle

```css
/* Leveydet */
--content-max-width: min(95vw, 1400px)   /* Koko sivun max */
--article-max-width: min(90vw, 800px)     /* Artikkeli */
--card-max-width: min(90vw, 600px)        /* Kortit */
--sidebar-width: max(250px, 20vw)         /* Sivupalkki */

/* Typography */
--text-xs: clamp(0.75rem, 1vw, 0.875rem)
--text-sm: clamp(0.875rem, 1.5vw, 1rem)
--text-base: clamp(1rem, 2vw, 1.25rem)
--text-lg: clamp(1.125rem, 2.5vw, 1.5rem)
--text-xl: clamp(1.25rem, 3vw, 2rem)
--text-2xl: clamp(1.5rem, 4vw, 3rem)

/* Spacing */
--space-xs: clamp(0.25rem, 1vw, 0.5rem)
--space-sm: clamp(0.5rem, 2vw, 1rem)
--space-md: clamp(1rem, 3vw, 2rem)
--space-lg: clamp(2rem, 5vw, 4rem)
--space-xl: clamp(3rem, 8vw, 6rem)
```

## Mitä Välttää

❌ Älä sekoita media queryjä ja näitä tekniikoita samassa komponentissa
❌ Älä käytä liian monimutkaisia clamp-arvoja (max 3 parametria)
❌ Älä unohda `min()` ja `max()` järjestystä (pienempi aina ensin)
❌ Älä käytä container queryjä liian monta tasoa sisäkkäin

✅ Pidä arvot yksinkertaisina ja selkeinä
✅ Käytä CSS custom propertiesia toistuviin arvoihin
✅ Testaa eri ruuduilla (mobile, tablet, desktop)
✅ Käytä DaisyUI:n omia breakpointeja (sm:, md:, lg:) harvoin tarvittaessa

## Homesite-spesifiset Käyttötapaukset

### Blog Posts - Index
```heex
<div class="grid gap-[clamp(1rem,3vw,2rem)] w-[min(95vw,1400px)] mx-auto"
     style="grid-template-columns: repeat(auto-fit, minmax(min(100%, 350px), 1fr));">
  <!-- posts -->
</div>
```

### Blog Post - Show (single article)
```heex
<article class="w-[min(90vw,800px)] mx-auto">
  <div class="prose max-w-none">
    <h1 class="text-[clamp(1.5rem,4vw,3rem)]"><%= @post.title %></h1>
    <div class="text-[clamp(1rem,2vw,1.25rem)]">
      <%= raw @post.body %>
    </div>
  </div>
</article>
```

### Tag Management
```heex
<div class="w-[min(90vw,1000px)] mx-auto">
  <div class="card bg-base-100 shadow-xl">
    <div class="card-body p-[clamp(1.5rem,4vw,3rem)]">
      <!-- tag form & list -->
    </div>
  </div>
</div>
```

### User Settings
```heex
<div class="w-[min(90vw,600px)] mx-auto">
  <div class="card bg-base-100 shadow-xl">
    <div class="card-body p-[clamp(1.5rem,4vw,3rem)]">
      <!-- settings forms -->
    </div>
  </div>
</div>
```

## Debuggaus & Testaus

### Tarkista breakpointit käsin
```heex
<!-- Väliaikainen debug-komponentti -->
<div class="fixed bottom-4 right-4 badge badge-info">
  <span class="block sm:hidden">XS</span>
  <span class="hidden sm:block md:hidden">SM</span>
  <span class="hidden md:block lg:hidden">MD</span>
  <span class="hidden lg:block xl:hidden">LG</span>
  <span class="hidden xl:block">XL</span>
</div>
```

### Testaa eri leveyksiä
- Mobile: 375px (iPhone SE)
- Tablet: 768px (iPad)
- Desktop: 1440px
- Wide: 1920px+

## Seuraavat Askeleet

1. **Aloita yhdestä näkymästä** - esim. blog-listaus
2. **Korvaa kiinteät arvot** clamp/min/max -arvoilla
3. **Testaa käytännössä** eri ruuduilla
4. **Refaktoroi toistuvia arvoja** CSS custom propertiesiksi
5. **Lisää container queries** jos tarvitaan komponenttitason responsiivisuutta

Muista: **Yksinkertainen ja toimiva > Täydellinen ja monimutkainen**
