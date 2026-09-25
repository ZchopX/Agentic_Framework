// Shows search results as the user types.
const input = document.querySelector('#q');
const list = document.querySelector('#results');

input.addEventListener('input', async () => {
  const q = input.value;
  const res = await fetch(`/api/search?q=${encodeURIComponent(q)}`);
  const items = await res.json();
  list.replaceChildren(
    ...items.map((item) => Object.assign(document.createElement('li'), { textContent: item.title }))
  );
});
