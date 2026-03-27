function playStartBeep() {
    var audio = new Audio('https://actions.google.com/sounds/v1/alarms/digital_alarm_clock.ogg');
    audio.volume = 0.8;
    audio.play().catch(e => console.log('Audio play failed:', e));
}

function playSuccessBeep() {
    var audio = new Audio('https://actions.google.com/sounds/v1/alarms/beep_short.ogg');
    audio.volume = 0.7;
    audio.play().catch(e => console.log('Audio play failed:', e));
}

function playErrorBeep() {
    var audio = new Audio('https://actions.google.com/sounds/v1/alarms/beep_error.ogg');
    audio.volume = 0.7;
    audio.play().catch(e => console.log('Audio play failed:', e));
}

// Force focus on scanner input every 2 seconds
setInterval(function() {
    var elem = document.getElementById('master_scanner_input');
    if (elem && document.activeElement !== elem && elem.offsetParent !== null) {
        elem.focus();
    }
}, 2000);