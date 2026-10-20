<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

## Site architecture
- Keep the supplied standalone HTML site intact; apply only targeted patches because it is the authoritative design and content.
- Keep branding synchronized between the standalone HTML head and the TanStack entry head because the entry redirects visitors to the HTML site.
- Keep generated logo concepts in source assets, use CDN pointers for processed web images, and a small public favicon because the standalone HTML cannot import bundled images.
