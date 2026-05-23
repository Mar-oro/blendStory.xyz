// auth-guard.js — blendStory.xyz
// Include with correct relative depth path on any protected page.
// Page refresh = re-login by design. sessionStorage only.
(function () {
    var TOKEN_KEY = 'blendstory_token';
    var token = sessionStorage.getItem(TOKEN_KEY);

    var base = (location.pathname.match(/^(.*\/docs\/)/) || ['', '/'])[1];
    var loginUrl = base + 'login/';

    function redirect() { window.location.replace(loginUrl); }

    if (!token) { redirect(); return; }

    try {
        var payload = JSON.parse(atob(token.split('.')[1]));
        if (payload.exp && payload.exp < Date.now() / 1000) {
            sessionStorage.removeItem(TOKEN_KEY);
            redirect();
        }
    } catch (e) {
        sessionStorage.removeItem(TOKEN_KEY);
        redirect();
    }
})();
