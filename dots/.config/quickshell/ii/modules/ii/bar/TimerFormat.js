.pragma library

function pad2(value) {
    return Math.floor(value).toString().padStart(2, "0");
}

function formatStopwatch(time) {
    const seconds = Math.floor(time / 100);
    const minutes = Math.floor(seconds / 60);
    return `${pad2(minutes)}:${pad2(seconds % 60)}.${pad2(time % 100)}`;
}

function formatPomodoro(seconds) {
    return `${pad2(seconds / 60)}:${pad2(seconds % 60)}`;
}

function formatVerticalStopwatch(time) {
    const seconds = Math.floor(time / 100);
    return `${pad2(seconds % 60)}\n${pad2(time % 100)}`;
}

function formatVerticalPomodoro(seconds) {
    return `${pad2(seconds / 60)}\n${pad2(seconds % 60)}`;
}
