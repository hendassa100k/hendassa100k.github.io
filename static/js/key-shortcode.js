document.addEventListener('DOMContentLoaded', function() {
  document.querySelectorAll('.key-copy-btn').forEach(btn => {
    btn.addEventListener('click', async function() {
      try {
        let prevBtn = "";

        const featherUrl = document.getElementById('config').getAttribute("data-feather-url");
        const codeBlock = btn.previousElementSibling;
        const text = codeBlock.textContent;

        await navigator.clipboard.writeText(text);
                
        prevBtn = btn.innerHTML;
        btn.innerHTML = `<svg class="feather"><use href="${featherUrl}#check"/></svg><br>Copied!`;
        
        setTimeout(() => btn.innerHTML = prevBtn, 1000);
      } catch (err) {
        console.error('Failed to copy:', err);
        btn.innerHTML = '<svg class="feather"><use href="/svg/feather-sprite.svg#x"/></svg><br>Error';
      }
    });
  });
});

