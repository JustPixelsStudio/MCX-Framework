let deathOpen = false;
let currentTime = 0;
let respawnFee = 0;

function setVisible(state) {
    const root = document.getElementById("death-root");
    if (!root) return;
    if (state) {
        root.classList.remove("hidden");
    } else {
        root.classList.add("hidden");
    }
}

function setTimerDisplay(seconds) {
    const minsEl = document.getElementById("timer-minutes");
    const secsEl = document.getElementById("timer-seconds");
    if (!minsEl || !secsEl) return;

    seconds = Math.max(0, Math.floor(seconds));
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;

    minsEl.textContent = String(m).padStart(2, "0");
    secsEl.textContent = String(s).padStart(2, "0");
}

function enableRespawnHint(fee) {
    const hint = document.getElementById("respawn-hint");
    const feeEl = document.getElementById("respawn-fee-text");
    if (!hint || !feeEl) return;

    hint.classList.remove("hidden");
    feeEl.textContent = fee > 0 ? `$${fee}` : "$0";
}

window.addEventListener("message", (event) => {
    const data = event.data || {};
    if (!data.action) return;

    if (data.action === "OPEN") {
        deathOpen = true;
        currentTime = data.time || 0;
        respawnFee = data.respawnFee || 0;
        setVisible(true);
        setTimerDisplay(currentTime);
    } else if (data.action === "UPDATE_TIMER") {
        currentTime = data.time || 0;
        setTimerDisplay(currentTime);
    } else if (data.action === "ENABLE_RESPAWN") {
        respawnFee = data.respawnFee || 0;
        enableRespawnHint(respawnFee);
    } else if (data.action === "CLOSE") {
        deathOpen = false;
        setVisible(false);
    }
});
