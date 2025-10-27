let menu = true;
let jobList = {};
let currentJobIndex = null;
let progressStatus = null
let playerLevel = 0

window.addEventListener("message", function (event) {
  if (event.data.action === "open") {
    $("html,body").css("display", "flex").show();
    jobList = event.data.list || [];
    progressStatus = event.data.xp
    updateLevelUI(progressStatus);
    loadModelData()
  }
});

$('.filterMenu').click(function() {
  if (menu) {
    $('.menu-items').show();
    menu = false;
    $('#down').css('rotate', '360deg')
  } else {
    $('.menu-items').hide();
    menu = true;
    $('#down').css('rotate', '270deg')
  }
});

document.getElementById("trailerInput").addEventListener("input", function () {
  var filter = this.value.toLowerCase(); 
  var items = document.querySelectorAll(".trailerItem");
  if (filter === "") {
    items.forEach(function (item) {
      item.style.display = ""; 
    });
    return;
  }
  items.forEach(function (item) {
    var carNameElement = item.querySelector(".trailerName");
    var carLogoElement = item.querySelector(".trailerType");
    var carName = carNameElement ? carNameElement.textContent.trim() || carNameElement.innerText.trim() : "";
    var carLogo = carLogoElement ? carLogoElement.textContent.trim() || carLogoElement.innerText.trim() : "";

    if (carName.toLowerCase().includes(filter) || carLogo.toLowerCase().includes(filter)) {
      item.style.display = ""; 
    } else {
      item.style.display = "none"; 
    }
  });
});

$(document).on("click", ".closeIcon", function() { 
  $("html,body").hide()
  $.post("https://savana-busjob/nuiOff",function () {})
})

$(document).on("click", "#confirm", function () {
  if (currentJobIndex !== null) {
    const selectedJob = jobList[currentJobIndex];
    $(".popUp").hide();
    $("html,body").hide();
    $.post("https://savana-busjob/nuiOff", function () {});
    $.post("https://savana-busjob/startJob", JSON.stringify({
      job: selectedJob,
      index: currentJobIndex
    }), function () {
    });
  } else {
    console.error("No job selected!");
  }
});

$(document).on("click", ".trailerItem", function () {
  const popUp = $(".popUp");
  const trailerName = $(this).find(".trailerName").text();
  currentJobIndex = $(this).index();
  if ($(this).hasClass("active")) {
    $(this).removeClass("active").css("background", "rgba(255, 255, 255, 0.03)");

    currentJobIndex = null;
    popUp.removeClass("active").fadeOut(200);
  } else {
    $(".trailerItem").removeClass("active").css("background", "rgba(255, 255, 255, 0.03)");

    $(this).addClass("active").css(
      "background",
      "linear-gradient(90deg, rgba(153, 153, 153, 0) 0%, rgba(224, 139, 20, 0.12) 58.13%)"
    );



    popUp.addClass("active").fadeIn(200);
  }
});

$(document).on("click", ".cancelText", function() {
    $('.popUp').hide()
    $(".trailerItem").removeClass("active").css("background", "rgba(255, 255, 255, 0.03)");
})

let currentSortOrder = ""; 

function loadModelData() {
  const container = document.querySelector(".listArea");
  container.innerHTML = ""; 

  if (currentSortOrder === "desc") {
    jobList.sort((a, b) => b.totalPrice - a.totalPrice);
  } else if (currentSortOrder === "asc") {
    jobList.sort((a, b) => a.totalPrice - b.totalPrice);
  } else if (currentSortOrder === "farthest") {
    jobList.sort((a, b) => b.distance - a.distance);
  } else if (currentSortOrder === "shortest") {
    jobList.sort((a, b) => a.distance - b.distance);
  }

  jobList.forEach((job, index) => {
    const itemDiv = document.createElement("div");
    itemDiv.classList.add("trailerItem");

    if (parseInt(job.level) <= parseInt(playerLevel)) {
      itemDiv.innerHTML = `
        <div id="trailerImg">
          <img src="${job.imgSrc}" alt="Job Image">
        </div>
        <div id="trailerInfo">
          <div class="trailerName">${job.name}</div>
          <div class="trailerRoute">Total Stop Count: ${job.stopcount}</div>
          <div class="trailerPrice">Total Price: $${job.totalPrice}</div>
          <div class="trailerPrice">Earn XP: ${job.giveXp}</div>
        </div>
      `;
    } else {
      itemDiv.innerHTML = `
        <div class="locked-overlay">
          🔒 Required Level ${job.level}
        </div>
        <div id="trailerImg">
          <img src="${job.imgSrc}" alt="Job Image">
        </div>
        <div id="trailerInfo">
          <div class="trailerName">${job.name}</div>
          <div class="trailerRoute">Total Stop Count : ${job.stopcount}</div>
          <div class="trailerPrice">Total Price : $${job.totalPrice}</div>
          <div class="trailerPrice">Earn XP : ${job.giveXp}</div>
        </div>
      `;
      itemDiv.classList.add("locked");
    }

    container.appendChild(itemDiv);
  });
}

$('#increasing').click(function() {
  currentSortOrder = "desc";
  loadModelData();
});

$('#declinling').click(function() {
  currentSortOrder = "asc"; 
  loadModelData(); 
});

$('#farthest').click(function() {
  currentSortOrder = "farthest";
  loadModelData();
});

$('#shortest').click(function() {
  currentSortOrder = "shortest"; 
  loadModelData(); 
});




function updateLevelUI(currentXP) {
  const maxXP = 100; 
  let level = Math.floor(currentXP / maxXP) + 1; 
  let xpInCurrentLevel = currentXP % maxXP;
  playerLevel = level

  $(".levelStatus").css('width', `${xpInCurrentLevel}%`);

  const levelTextDiv = document.querySelector(".levelText");

  levelTextDiv.textContent = `${xpInCurrentLevel}/${maxXP} Level ${level}`;
}

window.addEventListener("keyup", (event) => {
  event.preventDefault();
  if (event.key == "Escape") {
      $('html,body').hide()
      $.post('https://savana-busjob/nuiOff',JSON.stringify({}),function () {});            
  }
})
