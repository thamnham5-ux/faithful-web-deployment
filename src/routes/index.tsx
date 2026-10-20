import { createFileRoute } from "@tanstack/react-router";
import { useEffect } from "react";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "CHÍ QUY® — Creative Department" },
      { name: "description", content: "CHÍ QUY® — Creative Department: website, video & trải nghiệm sự kiện tại Hà Nội." },
      { property: "og:title", content: "CHÍ QUY® — Creative Department" },
      { property: "og:description", content: "Creative department làm website, video và trải nghiệm sự kiện. Chọn demo, đặt mua và phát triển theo ý bạn." },
      { property: "og:type", content: "website" },
      { property: "og:image:width", content: "1200" },
      { property: "og:image:height", content: "630" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: Index,
});

function Index() {
  useEffect(() => {
    window.location.replace("/site.html" + window.location.hash);
  }, []);
  return null;
}
