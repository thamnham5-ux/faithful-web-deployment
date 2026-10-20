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
- Store every web image (current and future) as a real file under public/images and reference it by /images/... path, never CDN asset pointers, because the site is also deployed from GitHub to Netlify where Lovable CDN URLs do not resolve.
- Keep standalone motion input-neutral with Pointer Events, viewport-entry reveals and an animated CSS fallback when WebGL is unavailable; respect the visitor's reduced-motion setting rather than gating effects by device type.
