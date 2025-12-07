let selectedSpawn = null;
let lastLocationAvailable = false;

function postNUI(name, data) {
    fetch(`https://${GetParentResourceName()}/${name}`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(data || {})
    }).catch((e) => console.log("NUI post error", e));
}

function clearActiveSpawn() {
    document.querySelectorAll(".spawn-option").forEach((el) => {
        el.classList.remove("active");
    });
}

function buildSpawnList(spawns) {
    const list = document.getElementById("spawn-list");
    list.innerHTML = "";

    if (!Array.isArray(spawns) || spawns.length === 0) {
        const info = document.createElement("div");
        info.className = "spawn-info";
        info.textContent = "No custom spawns provided. The server will use a default spawn.";
        list.appendChild(info);
        return;
    }

    spawns.forEach((spawn, index) => {
        const el = document.createElement("div");
        el.className = "spawn-option";
        el.dataset.index = index;

        const title = document.createElement("div");
        title.className = "spawn-label";
        title.textContent = spawn.label || `Spawn #${index + 1}`;

        const pos = document.createElement("div");
        pos.className = "spawn-meta";
        if (spawn.x && spawn.y && spawn.z) {
            pos.textContent = `X: ${Number(spawn.x).toFixed(1)}  Y: ${Number(spawn.y).toFixed(1)}  Z: ${Number(spawn.z).toFixed(1)}`;
        } else {
            pos.textContent = "Position will be resolved by server.";
        }

        el.appendChild(title);
        el.appendChild(pos);

        el.addEventListener("click", () => {
            clearActiveSpawn();
            el.classList.add("active");

            selectedSpawn = {
                x: spawn.x,
                y: spawn.y,
                z: spawn.z,
                heading: spawn.heading,
                label: spawn.label
            };
        });

        list.appendChild(el);
    });
}

function openSpawnSelector(spawns, lastLocationFlag) {
    lastLocationAvailable = !!lastLocationFlag;

    document.getElementById("mcx_ui_root").classList.remove("hidden");
    document.getElementById("spawn").classList.remove("hidden");

    const lastBtn = document.getElementById("btn_last_location");
    if (lastLocationAvailable) {
        lastBtn.classList.remove("disabled");
    } else {
        lastBtn.classList.add("disabled");
    }

    buildSpawnList(spawns);
}

function closeAll() {
    document.getElementById("mcx_ui_root").classList.add("hidden");
    document.getElementById("spawn").classList.add("hidden");
    clearActiveSpawn();
    selectedSpawn = null;
}

window.addEventListener("message", function (event) {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === "openSpawnSelector") {
        openSpawnSelector(data.spawns || [], data.last_location_available);
    } else if (data.action === "closeAll") {
        closeAll();
    }
});

function selectLastLocation() {
    if (!lastLocationAvailable) {
        return;
    }
    clearActiveSpawn();
    selectedSpawn = { type: "last_location" };
}

function confirmSpawn() {
    if (!selectedSpawn) {
        alert("Please select a spawn location or choose Last Location.");
        return;
    }

    postNUI("chooseSpawn", selectedSpawn);
    postNUI("closeUI", {});
}

function cancelSpawn() {
    postNUI("closeUI", {});
}

document.addEventListener("DOMContentLoaded", () => {
    document.getElementById("btn_spawn_confirm").addEventListener("click", confirmSpawn);
    document.getElementById("btn_spawn_cancel").addEventListener("click", cancelSpawn);
    document.getElementById("btn_last_location").addEventListener("click", selectLastLocation);

    document.addEventListener("keyup", (e) => {
        if (e.key === "Escape") {
            cancelSpawn();
        }
    });
});
