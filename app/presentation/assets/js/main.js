(() => {
  document.addEventListener('DOMContentLoaded', () => {
    // --- Tooltip initialization ---
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.forEach(el => new bootstrap.Tooltip(el));

    // --- Elements used across sections ---
    const searchInput = document.getElementById('spotify_query_input');
    const errorMsg = document.getElementById('error');
    const switcher = document.querySelector('.pill-switch');
    const slider = switcher?.querySelector('.slider');
    const links = switcher ? switcher.querySelectorAll('.nav-link') : [];
    const submitBtn = document.getElementById('submitBtn');
    const categoryInput = document.getElementById('category');
    const form = document.getElementById('spotify-form');
    const historyContainer = document.getElementById('searchHistoryContainer');

    // --- Page context ---
    const isHome = window.location.pathname === '/';
    console.log('[init] isHome =', isHome);

    // --- Placeholders map ---
    const placeholders = {
      song_name: 'e.g. Shape of You',
      singer: 'e.g. Taylor Swift'
    };

    // --- Helpers for pill switch ---
    const getActiveLink = () => switcher?.querySelector('.nav-link.active');

    const setActive = (link) => {
      if (!switcher || !slider) return;
      links.forEach(a => {
        a.classList.remove('active', 'text-white');
        a.setAttribute('aria-selected', 'false');
      });
      link.classList.add('active', 'text-white');
      link.setAttribute('aria-selected', 'true');

      const cat = link.dataset.category || 'song_name';
      if (categoryInput) categoryInput.value = cat;
      if (searchInput) searchInput.placeholder = placeholders[cat] || 'Enter keywords to find songs';

      // ensure the correct history group is visible when switching pills
      toggleHistoryGroups(cat);

      const currentQuery = (searchInput?.value || '').trim();
      renderHistory(cat, currentQuery);

      requestAnimationFrame(() => {
        slider.style.left = link.offsetLeft + 'px';
        slider.style.width = link.offsetWidth + 'px';
      });
    };

    // --- Toggle which category group is visible (Song vs Singer) ---
    function toggleHistoryGroups(activeCat) {
      if (!historyContainer) return;
      const groups = historyContainer.querySelectorAll('.history-group');
      groups.forEach(g => {
        g.classList.toggle('d-none', g.dataset.category !== activeCat);
      });
    }

    // --- Strict prefix matching function ---
    function prefixMatch(text, q) {
      const t = (text || '').toLowerCase().trim();
      const qq = (q || '').toLowerCase().trim();
      if (!qq) return true;
      return t.startsWith(qq);
    }

    // --- Core renderer: category filter + strict prefix filter + container visibility gating ---
    function renderHistory(category, queryFromParam) {
      if (!historyContainer) return;

      // Determine query to use
      let rawQ = (queryFromParam || '').trim();
      const inputQ = (searchInput?.value || '').trim();

      if (!rawQ && inputQ) {
        rawQ = inputQ;
      }

      const q = rawQ.toLowerCase();
      const currentCat = (category || categoryInput?.value || 'song_name')
        .toLowerCase();

      const badges = Array.from(
        historyContainer.querySelectorAll('.history-badge')
      );

      let showCount = 0;

      badges.forEach(badge => {
        const badgeCat = (badge.dataset.category || '').toLowerCase();

        const rawText =
          badge.dataset.query ||
          badge.querySelector('.history-text')?.textContent ||
          '';
        const text = rawText.trim().toLowerCase();

        const match =
          badgeCat === currentCat && prefixMatch(text, q);

        badge.classList.toggle('filter-hidden', !match);

        if (match) showCount++;

        console.log('[history][filter]', {
          badgeText: text,
          badgeCat,
          q,
          match
        });
      });

      activeHistoryIndex = -1;
      clearHistoryHighlight();

      const focused = (document.activeElement === searchInput);
      historyContainer.style.display = focused && showCount > 0 ? 'block' : 'none';
    }

    // --- Show/hide history on input focus / outside click and live filter ---
    if (searchInput && historyContainer) {
      // focus: render with current text
      searchInput.addEventListener('focus', () => {
        const cat = categoryInput?.value || 'song_name';
        toggleHistoryGroups(cat);
        renderHistory(cat, searchInput.value);
      });

      // input: live strict-prefix filtering
      searchInput.addEventListener('input', () => {
        const cat = categoryInput?.value || 'song_name';
        toggleHistoryGroups(cat);
        renderHistory(cat, searchInput.value);
      });

      // keydown: keyboard navigation
      searchInput.addEventListener('keydown', (e) => {
        if (!historyContainer || historyContainer.style.display === 'none') return;

        const badges = getVisibleBadges();
        if (!badges.length) return;

        if (e.key === 'ArrowDown') {
          e.preventDefault();
          activeHistoryIndex = (activeHistoryIndex + 1) % badges.length;
          highlightHistoryByIndex(activeHistoryIndex);
        } else if (e.key === 'ArrowUp') {
          e.preventDefault();
          activeHistoryIndex = (activeHistoryIndex - 1 + badges.length) % badges.length;
          highlightHistoryByIndex(activeHistoryIndex);
        } else if (e.key === 'Enter') {
          if (activeHistoryIndex >= 0 && activeHistoryIndex < badges.length) {
            e.preventDefault();
            const badge = badges[activeHistoryIndex];
            chooseHistoryBadge(badge);
          }
        }
      });

      // click outside → close
      document.addEventListener('click', (e) => {
        if (!searchInput.contains(e.target) &&
          !historyContainer.contains(e.target) &&
          !e.target.closest('.pill-switch')) {
          historyContainer.style.display = 'none';
        }
      });
    }

    // --- Click a history item to search ---
    if (historyContainer) {
      function chooseHistoryBadge(badge) {
        if (!badge) return;

        const query = badge.dataset.query;
        const category = badge.dataset.category;
        if (!query || !category) return;

        if (searchInput) searchInput.value = query;
        if (categoryInput) categoryInput.value = category;

        const targetLink = Array.from(links).find(l => l.dataset.category === category);
        if (targetLink) setActive(targetLink);

        sessionStorage.setItem('lastCategory', category);
        sessionStorage.setItem('lastSearchQuery', (query || '').trim());

        console.log('[history] choose:', { category, query });

        if (form?.requestSubmit) {
          form.requestSubmit();
        } else {
          form?.submit();
        }
      }

      // --- Choose history item ---
      historyContainer.addEventListener('click', (e) => {
        const historyText = e.target.closest('.history-text');
        if (!historyText) return;

        const badge = historyText.closest('.history-badge');
        chooseHistoryBadge(badge);
      });

      // --- Delete single history item ---
      historyContainer.addEventListener('mousedown', (e) => {
        const closeBtn = e.target.closest('.btn-close');
        if (closeBtn) {
          e.preventDefault();
        }
      });

      historyContainer.addEventListener('click', async (e) => {
        const closeBtn = e.target.closest('.btn-close');
        if (!closeBtn) return;

        e.stopPropagation();

        const query = closeBtn.dataset.query;
        const category = closeBtn.dataset.category;
        if (!query || !category) return;

        try {
          const params = new URLSearchParams({ category, query });
          const res = await fetch(`/search_history?${params.toString()}`, {
            method: 'DELETE'
          });

          if (res.ok || res.status === 204) {
            const badge = closeBtn.closest('.history-badge');
            if (badge) badge.remove();

            const cat = categoryInput?.value || 'song_name';
            const q = (searchInput?.value || '').trim();
            renderHistory(cat, q);

            keepSearchFocus();
            console.log('[history] deleted:', { category, query });
          } else {
            throw new Error(`HTTP ${res.status}`);
          }
        } catch (err) {
          console.error('[history] delete failed:', err);
        }
      });
    }

    function keepSearchFocus() {
      if (!searchInput) return;
      searchInput.focus({ preventScroll: true });
      const len = searchInput.value.length;
      requestAnimationFrame(() => {
        try { searchInput.setSelectionRange(len, len); } catch (_) { }
      });
    }

    // --- Keyboard navigation state for history ---
    let activeHistoryIndex = -1;

    function getVisibleBadges() {
      if (!historyContainer) return [];
      return Array.from(historyContainer.querySelectorAll('.history-badge'))
        .filter(badge => {
          return badge.offsetParent !== null;
        });
    }

    function clearHistoryHighlight() {
      if (!historyContainer) return;
      historyContainer
        .querySelectorAll('.history-badge.active')
        .forEach(b => b.classList.remove('active'));
    }

    function highlightHistoryByIndex(index) {
      const badges = getVisibleBadges();
      clearHistoryHighlight();
      if (!badges.length || index < 0 || index >= badges.length) return;

      const badge = badges[index];
      badge.classList.add('active');

      // Ensure the highlighted item is visible
      badge.scrollIntoView({ block: 'nearest' });

      // Set input value to the highlighted item's text
      const text = badge.dataset.query ||
        badge.querySelector('.history-text')?.textContent ||
        '';
      if (searchInput) searchInput.value = text;
    }

    // --- Remember on submit & reset on home ---
    if (searchInput) {
      if (isHome) {
        sessionStorage.removeItem('lastCategory');
        sessionStorage.removeItem('lastSearchQuery');
        searchInput.value = '';
        if (errorMsg) errorMsg.textContent = '';
      } else {
        const rememberedQuery = sessionStorage.getItem('lastSearchQuery');
        if (rememberedQuery) searchInput.value = rememberedQuery;
        if (errorMsg && !rememberedQuery) errorMsg.textContent = '';
      }
    }

    // --- Pill Switch + Search initialization ---
    if (switcher && slider && categoryInput && searchInput) {
      const DEFAULT_CAT = 'song_name';
      const rememberedCat = sessionStorage.getItem('lastCategory');
      const initialCategory = isHome
        ? DEFAULT_CAT
        : (['song_name', 'singer'].includes(rememberedCat || '') ? rememberedCat : DEFAULT_CAT);

      categoryInput.value = initialCategory;
      searchInput.placeholder = placeholders[initialCategory] || searchInput.placeholder || '';

      const initialLink =
        Array.from(links).find(a => (a.dataset.category || '') === initialCategory) || links[0];

      if (initialLink) {
        setActive(initialLink);
        console.log('[pill] initial active =', initialCategory);
      }

      // Render once using current input (kept hidden if input is not focused)
      toggleHistoryGroups(initialCategory);
      renderHistory(initialCategory, (searchInput?.value || '').trim());

      links.forEach(link => {
        link.addEventListener('click', e => {
          e.preventDefault();
          setActive(link);
          console.log('[pill] switched to =', link.dataset.category);
        });
      });

      if (form) {
        form.addEventListener('submit', () => {
          const active = getActiveLink();
          const cat = (active?.dataset.category) || categoryInput.value || DEFAULT_CAT;
          categoryInput.value = cat;

          sessionStorage.setItem('lastCategory', cat);
          sessionStorage.setItem('lastSearchQuery', (searchInput.value || '').trim());
          console.log('[submit] remember:', { cat, q: searchInput.value });
        });
      }

      const toggleSubmit = () => {
        if (submitBtn) submitBtn.disabled = !searchInput.value.trim();
      };
      searchInput.addEventListener('input', toggleSubmit);
      toggleSubmit();

      const relocate = () => {
        const a = getActiveLink();
        if (!a) return;
        requestAnimationFrame(() => {
          slider.style.left = a.offsetLeft + 'px';
          slider.style.width = a.offsetWidth + 'px';
        });
      };
      window.addEventListener('resize', relocate);
      window.addEventListener('load', relocate);
    }

    // --- Scroll behavior for .results-container ---
    document.addEventListener(
      'wheel',
      e => {
        const results = document.querySelector('.results-container');
        if (!results) return;

        const atTop = results.scrollTop === 0;
        const atBottom = results.scrollHeight - results.scrollTop === results.clientHeight;

        if (!results.contains(e.target)) {
          e.preventDefault();
          results.scrollTop += e.deltaY;
        } else if ((atTop && e.deltaY < 0) || (atBottom && e.deltaY > 0)) {
          e.preventDefault();
        }
      },
      { passive: false }
    );

    // --- Song Modal Logic ---
    const songModal = document.getElementById('songModal');
    const generateBtn = document.getElementById('btnStartLearning');
    let scrollPosition = 0;
    let currentSongId = null;

    function preventScroll(e) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    }

    if (songModal) {
      songModal.addEventListener('show.bs.modal', function () {
        scrollPosition = window.pageYOffset;

        document.body.style.overflow = 'hidden';
        document.body.style.position = 'fixed';
        document.body.style.top = `-${scrollPosition}px`;
        document.body.style.width = '100%';

        document.addEventListener('wheel', preventScroll, { passive: false });
        document.addEventListener('touchmove', preventScroll, { passive: false });
        document.addEventListener('scroll', preventScroll, { passive: false });
      });

      songModal.addEventListener('shown.bs.modal', () => {
        const container = getLyricsContainer();
        if (!container) return;

        const loadingEl = container.querySelector('.lyrics-loading');
        if (loadingEl && !loadingEl.classList.contains('d-none')) {
          buildLyricsSkeleton(container);
        }
      });

      songModal.addEventListener('hidden.bs.modal', function () {
        document.removeEventListener('wheel', preventScroll);
        document.removeEventListener('touchmove', preventScroll);
        document.removeEventListener('scroll', preventScroll);

        document.body.style.overflow = '';
        document.body.style.position = '';
        document.body.style.top = '';
        document.body.style.width = '';
        window.scrollTo(0, scrollPosition);
      });

      const modalLyrics = document.getElementById('modalLyrics');
      if (modalLyrics) {
        modalLyrics.addEventListener('wheel', function (e) {
          e.stopPropagation();
        });
        modalLyrics.addEventListener('touchmove', function (e) {
          e.stopPropagation();
        });
      }
    }

    // --- Start Learning button ---
    if (generateBtn) {
      generateBtn.addEventListener('click', () => {
        if (!currentSongId) return;
        window.location.href = `/songs/${currentSongId}/material`;
      });
    }


    // --- Card click -> open modal and load lyrics ---
    document.addEventListener(
      'click',
      (e) => {
        const card = e.target.closest('.song-card');
        if (!card) return;

        // Ignore clicks on singer links or play overlay
        if (e.target.closest('.singer-link') || e.target.closest('.play-overlay')) return;

        const singers = Array.from(card.querySelectorAll('.singer-link')).map(link => ({
          name: link.textContent.trim(),
          external_url: link.href
        }));

        const songData = {
          id: card.dataset.id || '',
          name: card.dataset.songName || '',
          album: card.dataset.albumName || '',
          cover: card.dataset.cover || '/assets/img/placeholder-album.png',
          url: card.dataset.url || '#',
          singers
        };

        updateSongModal(songData);

        const modalEl = document.getElementById('songModal');
        const bsModal = bootstrap.Modal.getOrCreateInstance(modalEl);
        bsModal.show();
      },
      true
    );

    // ====== helpers ======

    function getLyricsContainer() {
      return document.getElementById('modalLyrics');
    }

    function getDifficultyContainer() {
      return document.getElementById('difficultyStars');
    }

    function isCurrentSong(songId) {
      return songId === currentSongId;
    }

    // ====== Modal Update ======
    /**
     * Update Modal basic info, reset lyrics and difficulty, and start loading lyrics
     * @param {Object} data
     */
    function updateSongModal(data) {
      // Disable the Generate button until difficulty is loaded
      generateBtn.disabled = true;

      const modalEl = document.getElementById('songModal');
      if (!modalEl) return;

      // Mark the current song
      currentSongId = data.id;

      // Basic info
      modalEl.querySelector('#modalSongTitle').textContent = data.name;
      modalEl.querySelector('#modalAlbum').textContent = data.album;
      modalEl.querySelector('#modalCover').src = data.cover;
      modalEl.querySelector('#modalCover').alt = data.album || 'Cover';
      modalEl.querySelector('#modalPlayOverlay').href = data.url;

      // Singers list
      const singersEl = modalEl.querySelector('#modalSingers');
      if (data.singers?.length) {
        singersEl.innerHTML = data.singers
          .map(s => `<a class="singer-link" href="${s.external_url}" target="_blank" rel="noopener">${s.name}</a>`)
          .join(', ');
      } else {
        singersEl.textContent = 'Unknown';
      }

      // Lyrics: scroll to top and show loading skeleton
      const lyricsContainer = getLyricsContainer();
      if (lyricsContainer) {
        lyricsContainer.scrollTop = 0;
        resetLyricsDisplay(lyricsContainer);
      }

      // Difficulty: reset to loading state (skeleton)
      const starsContainer = getDifficultyContainer();
      if (starsContainer) resetDifficultyDisplay(starsContainer);

      // Start loading lyrics; only call fetchAndShowDifficulty after success
      loadLyrics(data.id);
    }

    // ====== Lyrics Loading ======
    /**
     * Load lyrics, then load difficulty after success
     * @param {string} songId
     */
    async function loadLyrics(songId) {
      const container = getLyricsContainer();
      if (!container) return;

      resetLyricsDisplay(container);

      try {
        const res  = await fetch(`/songs/${songId}/lyrics`, { cache: 'no-store' });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);

        const html = await res.text();
        if (!isCurrentSong(songId)) return;

        const loadingEl = container.querySelector('.lyrics-loading');
        const errorEl   = container.querySelector('.lyrics-error');
        const contentEl = container.querySelector('.lyrics-content');

        loadingEl?.classList.add('d-none');
        errorEl?.classList.add('d-none');

        if (contentEl) {
          contentEl.classList.remove('d-none');
          contentEl.innerHTML = html;
        }

        // handle error message from api view
        const errorMsgEl = contentEl.querySelector('.lyrics-api-error');
        if (errorMsgEl) throw new Error(errorMsgEl.textContent);

        // load difficulty only after lyrics success
        fetchAndShowDifficulty(songId);
      } catch (e) {
        if (!isCurrentSong(songId)) return;

        console.error('Lyrics error:', e);
        showLyricsError(e.message || 'Failed to load lyrics.');
        setDifficultyError();
      }
    }

    function resetLyricsDisplay(container) {
      const loadingEl = container.querySelector('.lyrics-loading');
      const errorEl   = container.querySelector('.lyrics-error');
      const contentEl = container.querySelector('.lyrics-content');

      loadingEl?.classList.remove('d-none');
      errorEl?.classList.add('d-none');

      if (contentEl) {
        contentEl.innerHTML = '';
        contentEl.classList.add('d-none');
      }
    }

    function showLyricsError(message) {
      const container = getLyricsContainer();
      if (!container) return;

      const loadingEl = container.querySelector('.lyrics-loading');
      const errorEl = container.querySelector('.lyrics-error');
      const contentEl = container.querySelector('.lyrics-content');
      const msgP = errorEl?.querySelector('p.text-danger');

      loadingEl?.classList.add('d-none');
      if (contentEl) {
        contentEl.innerHTML = '';
        contentEl.classList.add('d-none');
      }

      if (msgP && message) msgP.textContent = message;
      errorEl?.classList.remove('d-none');
    }

    function buildLyricsSkeleton(container) {
      const loadingEl = container.querySelector('.lyrics-loading');
      if (!loadingEl) return;

      loadingEl.innerHTML = '';

      let targetHeight = container.clientHeight || parseInt(container.style.maxHeight) || 240;
      console.log('[Lyrics Skeleton] build for height:', targetHeight);

      const block = 28;
      let usedHeight = 0;
      let safety = 50;
      let lineIndex = 0;

      while (usedHeight + block <= targetHeight && safety-- > 0) {
        const line = document.createElement('div');
        line.className = 'lyrics-skeleton-line';

        const widths = [95, 80, 63, 90, 74, 85]; // %
        const width = widths[lineIndex % widths.length];
        line.style.width = `${width}%`;

        loadingEl.appendChild(line);
        usedHeight += block;
        lineIndex += 1;
      }
    }

    window.addEventListener('resize', () => {
      const container = getLyricsContainer();
      if (!container) return;

      const loadingEl = container.querySelector('.lyrics-loading');
      const isLoading = loadingEl && !loadingEl.classList.contains('d-none');
      if (!isLoading) return;

      buildLyricsSkeleton(container);
    });

    // ====== Difficulty Loading ======
    /**
     * Fetch song difficulty and update stars in the footer
     * @param {string} songId
     */
    async function fetchAndShowDifficulty(songId) {
      console.log('LOAD DIFFICULTY start', songId);

      const starsContainer = getDifficultyContainer();
      if (!starsContainer) return;

      // If this song is no longer the current one, don't call the API
      if (!isCurrentSong(songId)) {
        console.log('[Difficulty] Skip fetch, outdated songId:', songId);
        return;
      }

      // Show loading skeleton and clear previous content
      resetDifficultyDisplay(starsContainer);

      try {
        const response = await fetch(`/songs/${songId}/level`, { cache: 'no-store' });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);

        const htmlFragment = await response.text();

        // When the response comes back, check again if it's still the current song
        if (!isCurrentSong(songId)) {
          console.log('[Difficulty] Response outdated, ignore:', songId);
          return;
        }

        const loadingEl = starsContainer.querySelector('.stars-loading');
        const contentEl = starsContainer.querySelector('.stars-content');

        loadingEl?.classList.add('d-none');
        if (!contentEl) {
          console.error('[Difficulty] .stars-content not found');
          setDifficultyError();
          return;
        }

        contentEl.innerHTML = htmlFragment;

        // Enable the Generate button
        generateBtn.disabled = false;
      } catch (error) {
        if (!isCurrentSong(songId)) return;

        console.error('Error fetching song level:', error);
        setDifficultyError();
      }
    }

    function setDifficultyError() {
      const starsContainer = getDifficultyContainer();
      if (!starsContainer) return;

      const loadingEl = starsContainer.querySelector('.stars-loading');
      const errorEl = starsContainer.querySelector('.stars-error');

      loadingEl?.classList.add('d-none');
      errorEl?.classList.remove('d-none');
    }

    function resetDifficultyDisplay(starsContainer) {
      const loadingEl = starsContainer.querySelector('.stars-loading');
      const errorEl = starsContainer.querySelector('.stars-error');
      let contentEl = starsContainer.querySelector('.stars-content');

      loadingEl?.classList.remove('d-none');
      errorEl?.classList.add('d-none');
      contentEl.innerHTML = '';
    }
    
    // ====== Material page only ======
    if (/^\/songs\/[^/]+\/material/.test(window.location.pathname)) {
      console.log('[material] script loaded, path =', window.location.pathname);

      // 左右翻頁 Material Card
      const materialCards = Array.from(document.querySelectorAll('.material-card'));
      const prevBtn = document.getElementById('materialPrev');
      const nextBtn = document.getElementById('materialNext');
      const counter = document.getElementById('materialCounter');
      const materialContainer = document.querySelector('.materials-scroll');

      let currentMaterialIndex = 0;

      function showMaterialCard(index) {
        if (!materialCards.length) return;

        if (index < 0) index = 0;
        if (index >= materialCards.length) index = materialCards.length - 1;
        currentMaterialIndex = index;

        materialCards.forEach(card => card.classList.add('d-none'));
        materialCards[currentMaterialIndex].classList.remove('d-none');

        if (materialContainer) {
          materialContainer.scrollTop = 0;
        }

        if (counter) {
          counter.textContent = `${currentMaterialIndex + 1} / ${materialCards.length}`;
        }

        if (prevBtn) prevBtn.disabled = (currentMaterialIndex === 0);
        if (nextBtn) nextBtn.disabled = (currentMaterialIndex === materialCards.length - 1);
      }

      // 給歌詞那邊用的全域函式
      window.showMaterialCard = showMaterialCard;

      if (materialCards.length) {
        showMaterialCard(0);
        setupMaterialStars(); // ★ 在這裡綁星星
      }

      if (prevBtn) {
        prevBtn.addEventListener('click', () => {
          showMaterialCard(currentMaterialIndex - 1);
        });
      }

      if (nextBtn) {
        nextBtn.addEventListener('click', () => {
          showMaterialCard(currentMaterialIndex + 1);
        });
      }

      // === Material page: 歌詞點擊 → 單字卡跳頁 ===
      const lyricsContainer = document.querySelector('.lyrics-text');

      console.log('[material] init, hasLyrics =', !!lyricsContainer, 'cards =', materialCards.length);

      // 共同的「正規化單字」函式：變小寫、去掉非字母與 '
      function normalizeKey(str) {
        return (str || '')
          .toLowerCase()
          .replace(/[^a-z']/g, '');
      }

      if (lyricsContainer && materialCards.length) {
        const vocabToIndex = {};
        materialCards.forEach((card, idx) => {
          // const raw =
          //   card.dataset.originWord ||
          //   card.getAttribute('data-origin-word') ||
          //   card.dataset.vocab ||
          //   (card.querySelector('.vocab-word') &&
          //   card.querySelector('.vocab-word').textContent) ||
          //   '';

          // const key = normalizeKey(raw);
          // if (key && !(key in vocabToIndex)) {
          //   vocabToIndex[key] = idx;
          // }
          materialCards.forEach((card, idx) => {
          const originRaw =
            card.dataset.originWord ||
            card.getAttribute('data-origin-word') ||
            '';

          const lemmaRaw =
            card.dataset.lemma ||
            card.getAttribute('data-lemma') ||
            card.dataset.vocab ||               // 兼容你舊的
            card.getAttribute('data-word') ||
            '';

          const originKey = normalizeKey(originRaw);
          const lemmaKey  = normalizeKey(lemmaRaw);

          // 同一張卡，存兩把 key（origin + lemma）
          if (originKey && !(originKey in vocabToIndex)) vocabToIndex[originKey] = idx;
          if (lemmaKey  && !(lemmaKey  in vocabToIndex)) vocabToIndex[lemmaKey]  = idx;
        });
        });

        console.log('[material] vocabToIndex keys =', Object.keys(vocabToIndex).slice(0, 20), '...');
        console.log('[material] has running?', 'running' in vocabToIndex,'idx=', vocabToIndex['running']);

        function showMaterialCardFromLyrics(idx) {
          showMaterialCard(idx);

          const pager = document.getElementById('materials_pager');
          if (pager) pager.textContent = `${idx + 1} / ${materialCards.length}`;
        }

        lyricsContainer.addEventListener('click', (e) => {
          const wordEl = e.target.closest('.lyrics-word');
          if (!wordEl) return;

          const raw =
            wordEl.dataset.vocab ||
            wordEl.textContent ||
            '';
          const key = normalizeKey(raw);

          const targetIndex = vocabToIndex[key];
          console.log('[material] click word:', raw, '→ key:', key, '→ index:', targetIndex);

          if (targetIndex == null) return;

          showMaterialCardFromLyrics(targetIndex);

          document.querySelectorAll('.lyrics-word--active')
            .forEach((el) => el.classList.remove('lyrics-word--active'));
          wordEl.classList.add('lyrics-word--active');
        });
      }
    }

    // ====== 收藏星星 ======
    function setupMaterialStars() {
      // 這個 selector 要跟你 HTML 一致：<i class="fas fa-star fav-star">
      const stars = document.querySelectorAll('.material-card .fav-star');
      console.log('[material] setupMaterialStars: found', stars.length, 'stars');

      if (!stars.length) return;

      stars.forEach((star) => {
        star.addEventListener('click', (e) => {
          e.preventDefault();
          e.stopPropagation(); // 避免點星星的 click 影響到其他 handler

          star.classList.toggle('is-fav');
          console.log('[material] star clicked, isFav =', star.classList.contains('is-fav'));
        });
      });
    }

    // --- Tutorial ---
    const sidebar = document.getElementById('sidebar');
    const toggleBtn = document.getElementById('sidebarToggle');
    const mainContent = document.getElementById('main-content');
    const navLinks = document.querySelectorAll('.nav-link-custom');
    const sections = document.querySelectorAll('.section-spy');

    // 1. Sidebar 收合功能
    // 增加 null check 防止如果在其他頁面引用此 JS 會報錯
    if (toggleBtn && sidebar) {
        toggleBtn.addEventListener('click', function() {
            sidebar.classList.toggle('collapsed');
        });
    }

    // 2. 平滑滾動 (點擊左側導航)
    navLinks.forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const targetId = this.getAttribute('href').substring(1);
            const targetSection = document.getElementById(targetId);
            
            if (targetSection && mainContent) {
                // 計算滾動位置
                const topPos = targetSection.offsetTop;
                // 注意：這裡不需要減去 header 高度，因為 mainContent 是獨立滾動的
                mainContent.scrollTo({
                    top: topPos - 20, 
                    behavior: 'smooth'
                });
                
                updateActiveLink(targetId);
            }
        });
    });

    function updateActiveLink(id) {
        navLinks.forEach(link => {
            link.classList.remove('active');
            if(link.getAttribute('href') === '#' + id) {
                link.classList.add('active');
            }
        });
    }

    // 3. ScrollSpy (滾動監聽)
    // 確保有元素才執行
    if (mainContent && sections.length > 0) {
        const observerOptions = {
            root: mainContent, 
            rootMargin: '-20% 0px -60% 0px', 
            threshold: 0
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    updateActiveLink(entry.target.id);
                }
            });
        }, observerOptions);

        sections.forEach(section => {
            observer.observe(section);
        });
    }
  });
})();
