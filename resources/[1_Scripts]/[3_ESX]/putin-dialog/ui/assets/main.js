let currentMenuAction

$(document).ready(function(){
	window.addEventListener('message', function(event) {
		let item = event.data
		if (item.action == 'showDialog') {
			playOpenSound()
			handleDialog(item)
		}
	});
	$('#close').click(function () {
		playCloseSound()
		$.post('https://putin-dialog/exit', JSON.stringify({}));
		$('#container').hide()
		$("#container").css("display", "none");
		currentMenuAction = null
	});
});

function playOpenSound() {
  var soundO = new Audio('assets/sound_open.mp3');
  soundO.volume = 0.5;
  soundO.play();
}

function playCloseSound() {
  var soundC = new Audio('assets/sound_close.mp3');
  soundC.volume = 0.4;
  soundC.play();
}

function playSubmitSound() {
  var soundS = new Audio('assets/sound_submit.mp3');
  soundS.volume = 0.5;
  soundS.play();
}

function handleDialog(item) {
	if ( item.textarea ) {
		$("#input").replaceWith($('<textarea placeholder="Ecrivez ici " class="form-control" id="input"></textarea>'));
	} else {
		$("#input").replaceWith($('<input placeholder="Ecrivez ici " class="form-control" id="input"></input>'));
	}

	var inputElement = document.getElementById("input");
	inputElement.maxLength = item.maxLength;

	if ( item.pushEnter ) {
		$('#input').on('keydown', function(event) {
			submitWithKey(event);
		});
	}

    $("#container").show();
	$("#container").css("display", "flex");
    $('#input').val(item.defaultInput)
	$('#input').focus()
    $('#dialogLabel').html(item.label)
    $('#hint').text(item.helpText)
	currentMenuAction = item.menuAction
}

$(document).keyup(function (event) {
	if (event.which == 27) {
		playCloseSound()
		$.post('https://putin-dialog/exit', JSON.stringify({}));
		$('#container').hide();
		$("#container").css("display", "none");
		currentMenuAction = null
		return
	}
});

function submitWithKey(event) {
	if (event.keyCode === 13) {
		event.preventDefault();
		playSubmitSound()
		let dialog = $("#input").val()
		const data = JSON.stringify({ text: dialog, currMA: currentMenuAction })
		$.post('https://putin-dialog/submit', data);
		currentMenuAction = null
		$('#container').hide()
		$("#container").css("display", "none");
		return
	}
}


$(document).submit(function( event ) {
	event.preventDefault();
	playSubmitSound()
	let dialog = $("#input").val()
	const data = JSON.stringify({ text: dialog, currMA: currentMenuAction })
	$.post('https://putin-dialog/submit', data);
	currentMenuAction = null
	$('#container').hide()
	$("#container").css("display", "none");
});