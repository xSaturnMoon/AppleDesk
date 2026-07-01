import Foundation

enum SpotifyBridge {

    /// Legge lo stato del player (Media Session API + fallback DOM).
    static let readState = """
    (function() {
        function pick(selectors) {
            for (var i = 0; i < selectors.length; i++) {
                var el = document.querySelector(selectors[i]);
                if (el) return el;
            }
            return null;
        }
        function label(el) {
            return el ? (el.getAttribute('aria-label') || '').toLowerCase() : '';
        }
        function text(el) {
            return el ? (el.textContent || '').trim() : '';
        }

        var playBtn = pick([
            '[data-testid="control-button-playpause"]',
            'button[aria-label*="Pause"]',
            'button[aria-label*="Play"]'
        ]);
        var isPlaying = label(playBtn).includes('pause');

        var repeatBtn = document.querySelector('[data-testid="control-button-repeat"]');
        var repeatLabel = label(repeatBtn);
        var repeatMode = 'off';
        if (repeatLabel.includes('track')) repeatMode = 'track';
        else if (repeatLabel.includes('on') || repeatLabel.includes('all')) repeatMode = 'all';

        var shuffleBtn = document.querySelector('[data-testid="control-button-shuffle"]');
        var shuffleOn = label(shuffleBtn).includes('on');

        var progress = 0, positionMs = 0, durationMs = 0;
        var progressRoot = pick([
            '[data-testid="playback-progressbar"]',
            'div[role="slider"][aria-valuenow]'
        ]);
        if (progressRoot) {
            var now = parseFloat(progressRoot.getAttribute('aria-valuenow') || '0');
            var max = parseFloat(progressRoot.getAttribute('aria-valuemax') || '0');
            if (max > 0) {
                positionMs = Math.round(now);
                durationMs = Math.round(max);
                progress = now / max;
            }
        }

        var title = '', artist = '', album = '', artworkUrl = null;

        if (navigator.mediaSession && navigator.mediaSession.metadata) {
            var meta = navigator.mediaSession.metadata;
            title = meta.title || '';
            artist = meta.artist || '';
            album = meta.album || '';
            if (meta.artwork && meta.artwork.length) {
                artworkUrl = meta.artwork[meta.artwork.length - 1].src;
            }
            if (navigator.mediaSession.playbackState === 'playing') isPlaying = true;
            if (navigator.mediaSession.playbackState === 'paused') isPlaying = false;
        }

        if (!title) {
            var titleNode = pick([
                '[data-testid="context-item-info-title"]',
                '[data-testid="now-playing-widget"] [data-testid="context-item-link"]',
                'a[data-testid="entityTitle"]',
                '[data-testid="now-playing-widget"] span'
            ]);
            title = text(titleNode);
        }
        if (!artist) {
            var artistNode = pick([
                '[data-testid="context-item-info-artist"] a',
                '[data-testid="context-item-info-artist"]',
                '[data-testid="now-playing-widget"] [data-testid="context-item-info-subtitles"] a'
            ]);
            artist = text(artistNode);
        }
        if (!artworkUrl) {
            var img = pick([
                'img[data-testid="cover-art-image"]',
                '[data-testid="now-playing-widget"] img',
                'img[alt*="Album"]'
            ]);
            if (img && img.src) artworkUrl = img.src;
        }

        var onLoginPage = (location.pathname || '').indexOf('/login') >= 0
            || (location.pathname || '').indexOf('/signup') >= 0;

        return {
            title: title,
            artist: artist,
            album: album,
            artworkUrl: artworkUrl,
            isPlaying: isPlaying,
            shuffleOn: shuffleOn,
            repeatMode: repeatMode,
            progress: progress,
            positionMs: positionMs,
            durationMs: durationMs,
            onLoginPage: onLoginPage
        };
    })();
    """

    static let installObserver = """
    (function() {
        if (window.__appleDeskSpotifyBridgeTimer) {
            clearInterval(window.__appleDeskSpotifyBridgeTimer);
            window.__appleDeskSpotifyBridgeTimer = null;
        }
        if (window.__appleDeskSpotifyBridgeObs) {
            window.__appleDeskSpotifyBridgeObs.disconnect();
            window.__appleDeskSpotifyBridgeObs = null;
        }

        function collect() {
            return \(readState);
        }

        function emit() {
            try {
                window.webkit.messageHandlers.spotifyState.postMessage(collect());
            } catch (e) {}
        }

        window.__appleDeskSpotifyBridgeTimer = setInterval(emit, 900);
        document.addEventListener('visibilitychange', emit);

        var obs = new MutationObserver(function() { emit(); });
        var target = document.querySelector('[data-testid="now-playing-widget"]')
            || document.querySelector('[data-testid="player-controls"]')
            || document.body;
        obs.observe(target, { childList: true, subtree: true, attributes: true });
        window.__appleDeskSpotifyBridgeObs = obs;

        emit();
    })();
    """

    static let teardownObserver = """
    (function() {
        if (window.__appleDeskSpotifyBridgeTimer) {
            clearInterval(window.__appleDeskSpotifyBridgeTimer);
            window.__appleDeskSpotifyBridgeTimer = null;
        }
        if (window.__appleDeskSpotifyBridgeObs) {
            window.__appleDeskSpotifyBridgeObs.disconnect();
            window.__appleDeskSpotifyBridgeObs = null;
        }
    })();
    """

    /// Ferma anteprime e audio fuori dal player principale.
    static let suppressStrayPlayback = """
    (function() {
        var playerRoot = document.querySelector('[data-testid="now-playing-bar"]')
            || document.querySelector('[data-testid="player-controls"]')
            || document.querySelector('[data-testid="now-playing-widget"]');
        document.querySelectorAll('audio, video').forEach(function(el) {
            if (playerRoot && playerRoot.contains(el)) return;
            try { el.pause(); el.muted = true; el.autoplay = false; } catch (e) {}
        });
    })();
    """

    static let removeBanners = """
    (function() {
        var banner = document.querySelector('[data-testid="web-player-app-banner"]');
        if (banner) banner.remove();
        var smart = document.querySelector('.smart-banner');
        if (smart) smart.remove();
    })();
    """

    static let playPause = """
    (function() {
        var btn = document.querySelector('[data-testid="control-button-playpause"]');
        if (btn) { btn.click(); return true; }
        return false;
    })();
    """

    static let nextTrack = """
    (function() {
        var btn = document.querySelector('[data-testid="control-button-skip-forward"]');
        if (btn) { btn.click(); return true; }
        return false;
    })();
    """

    static let previousTrack = """
    (function() {
        var btn = document.querySelector('[data-testid="control-button-skip-back"]');
        if (btn) { btn.click(); return true; }
        return false;
    })();
    """

    static let toggleShuffle = """
    (function() {
        var btn = document.querySelector('[data-testid="control-button-shuffle"]');
        if (btn) { btn.click(); return true; }
        return false;
    })();
    """

    static let toggleRepeat = """
    (function() {
        var btn = document.querySelector('[data-testid="control-button-repeat"]');
        if (btn) { btn.click(); return true; }
        return false;
    })();
    """
}
