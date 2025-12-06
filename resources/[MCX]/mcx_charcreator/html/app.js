let selectedSpawn = null;

function postNUI(name, data) {
    fetch(`https://${GetParentResourceName()}/${name}`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(data || {})
    }).catch(e => console.log("NUI post error", e));
}

window.addEventListener("message", function(event) {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === "openCharacterCreator") {
        document.getElementById("mcx_ui_root").classList.remove("hidden");
        document.getElementById("creator").classList.remove("hidden");
        document.getElementById("spawn").classList.add("hidden");
    }

    if (data.action === "openSpawnSelector") {
        document.getElementById("mcx_ui_root").classList.remove("hidden");
        document.getElementById("spawn").classList.remove("hidden");
        document.getElementById("creator").classList.add("hidden");
        clearActiveSpawn();
        selectedSpawn = null;

        // Handle last_location: show/hide Last Location option and set coords
        const lastLocEl = document.getElementById("spawn_last_location");
        if (lastLocEl) {
            if (data.last_location && !isNaN(data.last_location.x) && !isNaN(data.last_location.y) && !isNaN(data.last_location.z)) {
                lastLocEl.classList.remove("hidden");
                lastLocEl.setAttribute("data-x", data.last_location.x);
                lastLocEl.setAttribute("data-y", data.last_location.y);
                lastLocEl.setAttribute("data-z", data.last_location.z);
            } else {
                lastLocEl.classList.add("hidden");
            }
        }
    }

    if (data.action === "closeAll") {
        document.getElementById("mcx_ui_root").classList.add("hidden");
        document.getElementById("creator").classList.add("hidden");
        document.getElementById("spawn").classList.add("hidden");
    }
});

document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll(".spawn-option").forEach(el => {
        el.addEventListener("click", () => {
            clearActiveSpawn();
            el.classList.add("active");
            const x = Number(el.getAttribute("data-x"));
            const y = Number(el.getAttribute("data-y"));
            const z = Number(el.getAttribute("data-z"));
            selectedSpawn = { x, y, z };
        });
    });
});

function clearActiveSpawn() {
    document.querySelectorAll(".spawn-option").forEach(el => {
        el.classList.remove("active");
    });
}

function submitCharacter() {
    const first = document.getElementById("first").value.trim();
    const last = document.getElementById("last").value.trim();
    const ped  = document.getElementById("ped_model").value;

    if (first.length < 2 || last.length < 2) {
        alert("Please enter a valid first and last name.");
        return;
    }

    postNUI("createCharacter", {
        first_name: first,
        last_name: last,
        ped_model: ped,
        skin: {}
    });
}

function confirmSpawn() {
    if (!selectedSpawn || isNaN(selectedSpawn.x) || isNaN(selectedSpawn.y) || isNaN(selectedSpawn.z)) {
        alert("Please select a spawn location first.");
        return;
    }

    postNUI("chooseSpawn", selectedSpawn);
    postNUI("closeUI", {});
}
