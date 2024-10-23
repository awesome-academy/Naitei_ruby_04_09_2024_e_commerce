document.addEventListener("turbo:load", function () {
  const selectAllCheckbox = document.getElementById('select_all');
  const checkboxes = document.querySelectorAll('input[name="order_ids[]"]');

  selectAllCheckbox.addEventListener('change', function () {
    checkboxes.forEach((checkbox) => {
      checkbox.checked = selectAllCheckbox.checked;
    });
  });

  checkboxes.forEach((checkbox) => {
    checkbox.addEventListener('change', function () {
      const allChecked = Array.from(checkboxes).every(cb => cb.checked);
      selectAllCheckbox.checked = allChecked;
    });
  });
});
