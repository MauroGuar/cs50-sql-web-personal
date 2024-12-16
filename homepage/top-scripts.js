const backBtn = document.querySelector("#back-btn");
backBtn.addEventListener("click", () => {
    // window.location.href = "index.html";
    window.history.back();
});
