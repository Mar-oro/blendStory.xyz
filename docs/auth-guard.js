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
        
        // Sync payload to user storage so role/id are available to dashboards
        var userKey = TOKEN_KEY.replace('_token', '_user');
        var existingUser = JSON.parse(sessionStorage.getItem(userKey) || '{}');
        // Merge payload into existing user data, preferring payload values
        var updatedUser = Object.assign({}, existingUser, payload);
        sessionStorage.setItem(userKey, JSON.stringify(updatedUser));

        if (payload.exp && payload.exp < Date.now() / 1000) {
            sessionStorage.removeItem(TOKEN_KEY);
            redirect();
        }
    } catch (e) {
        sessionStorage.removeItem(TOKEN_KEY);
        redirect();
    }
})();
