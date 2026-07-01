export async function onRequestGet(context) {
  return context.env.ASSETS.fetch(new URL('/watch/index.html', context.request.url));
}
