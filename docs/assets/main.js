document.addEventListener("DOMContentLoaded", () => {
  const revealItems = document.querySelectorAll(".reveal");
  const revealObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          revealObserver.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.18 }
  );

  revealItems.forEach((item) => revealObserver.observe(item));

  const cards = document.querySelectorAll(".timeline-card");
  const shots = document.querySelectorAll(".device-shot");
  const label = document.getElementById("journey-label");
  const title = document.getElementById("journey-title");
  const copy = document.getElementById("journey-copy");
  const reviewToggle = document.getElementById("review-toggle");
  const reviewToggleButtons = document.querySelectorAll("[data-review-view]");
  const reviewPanels = document.querySelectorAll("[data-review-panel]");
  const deviceShell = document.querySelector(".device-shell");
  const journeyList = document.querySelector(".journey-list");
  
  // Create or get spacer
  let spacer = document.querySelector(".journey-spacer");
  if (!spacer) {
    spacer = document.createElement("div");
    spacer.className = "journey-spacer";
    journeyList.appendChild(spacer);
  }

  let activeShotId = null;
  let reviewAutoplay = null;

  function setReviewView(view) {
    reviewToggleButtons.forEach((button) => {
      const isActive = button.dataset.reviewView === view;
      button.classList.toggle("is-active", isActive);
      button.setAttribute("aria-selected", isActive ? "true" : "false");
    });

    reviewPanels.forEach((panel) => {
      panel.classList.toggle("is-active", panel.dataset.reviewPanel === view);
    });
  }

  function stopReviewAutoplay() {
    if (!reviewAutoplay) return;
    window.clearInterval(reviewAutoplay);
    reviewAutoplay = null;
  }

  function startReviewAutoplay() {
    stopReviewAutoplay();
    reviewAutoplay = window.setInterval(() => {
      const currentView = document.querySelector("[data-review-view].is-active")
        ?.dataset.reviewView;
      setReviewView(currentView === "table" ? "flashcard" : "table");
    }, 1600);
  }

  function activateCard(card) {
    if (!card) return;
    if (activeShotId === card.dataset.shot) return;

    cards.forEach((item) => item.classList.toggle("is-active", item === card));
    shots.forEach((item) =>
      item.classList.toggle("is-active", item.dataset.shotId === card.dataset.shot)
    );

    if (label) label.textContent = card.dataset.label;
    if (title) title.textContent = card.dataset.title;
    if (copy) copy.textContent = card.dataset.copy;
    activeShotId = card.dataset.shot;

    if (activeShotId === "review-dual") {
      reviewToggle?.classList.add("is-visible");
      startReviewAutoplay();
    } else {
      reviewToggle?.classList.remove("is-visible");
      stopReviewAutoplay();
    }
  }

  function updateSpacerHeight() {
    if (!deviceShell || cards.length === 0) return;
    
    const lastCard = cards[cards.length - 1];
    const shellHeight = deviceShell.offsetHeight;
    const lastCardHeight = lastCard.offsetHeight;
    
    // Calculate how much extra space we need so the last card's top can reach the shell's top
    // Height = shellHeight - lastCardHeight
    const spacerHeight = Math.max(0, shellHeight - lastCardHeight);
    spacer.style.height = `${spacerHeight}px`;
  }

  let frameRequest = null;

  function syncJourneyExperience() {
    frameRequest = null;

    const headerHeight =
      parseInt(
        getComputedStyle(document.documentElement).getPropertyValue(
          "--header-height"
        )
      ) || 88;
    const stickyTop = headerHeight + 1.5 * 16;

    const firstCard = cards[0];
    const lastCard = cards[cards.length - 1];
    const firstCardRect = firstCard?.getBoundingClientRect();
    const lastCardRect = lastCard?.getBoundingClientRect();

    // 1. 最後一個 Step 的對齊邏輯：上緣到達 Box 上緣
    if (lastCardRect && lastCardRect.top <= stickyTop) {
      activateCard(lastCard);
      return;
    }

    // 2. 第一個 Step 的初始對齊邏輯
    // 如果第一個 Step 還在 Box 上緣附近（或更高），預設啟動 Step 1
    if (firstCardRect && firstCardRect.top >= stickyTop - 50) {
      activateCard(firstCard);
      return;
    }

    // 3. 中間 Steps 的切換邏輯
    let bestCard = null;
    let bestDistance = Number.POSITIVE_INFINITY;

    cards.forEach((card) => {
      const rect = card.getBoundingClientRect();
      const distance = Math.abs(rect.top - stickyTop);

      if (distance < bestDistance) {
        bestDistance = distance;
        bestCard = card;
      }
    });

    activateCard(bestCard);
  }

  function requestJourneySync() {
    if (frameRequest !== null) return;
    frameRequest = window.requestAnimationFrame(syncJourneyExperience);
  }

  cards.forEach((card) => {
    card.addEventListener("click", () => activateCard(card));
    card.addEventListener("focus", () => activateCard(card));
    card.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        activateCard(card);
      }
    });
  });

  reviewToggleButtons.forEach((button) => {
    button.addEventListener("click", () => {
      setReviewView(button.dataset.reviewView);
      if (activeShotId === "review-dual") startReviewAutoplay();
    });
  });

  // Scroll to top logic without modifying URL
  const scrollToTopLinks = document.querySelectorAll('a[href="#"]');
  scrollToTopLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    });
  });

  // Initialization
  setReviewView("table");
  window.addEventListener("scroll", requestJourneySync, { passive: true });
  window.addEventListener("resize", () => {
    updateSpacerHeight();
    requestJourneySync();
  });
  
  // Run once after assets load
  window.addEventListener("load", () => {
    updateSpacerHeight();
    requestJourneySync();
  });

  // Initial call
  updateSpacerHeight();
  activateCard(cards[0]);
  requestJourneySync();
  
  // Handle image loads that might change layout
  document.querySelectorAll(".device-shell img").forEach((img) => {
    img.addEventListener("load", () => {
      updateSpacerHeight();
      requestJourneySync();
    });
  });
});
