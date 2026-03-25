import streamlit as st
import pandas as pd
from html import escape

from utils.data_handler import load_user_data, save_user_data
from utils.llm_chat import generate_response

st.set_page_config(page_title="Arise", page_icon="🌙", layout="wide")

st.markdown("""
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,600;1,300;1,400&family=Outfit:wght@300;400;500;600&display=swap" rel="stylesheet">

<style>
/* ── Design Tokens ── */
:root {
  --night:    #0b0e17;
  --night2:   #111520;
  --night3:   #171c2e;
  --panel:    #1a1f33;
  --panel2:   #1f2540;
  --rim:      rgba(255,255,255,0.06);
  --rim2:     rgba(255,255,255,0.10);
  --amber:    #e8a84c;
  --amber2:   #f0c07a;
  --amber-d:  #c47c1a;
  --teal:     #3ecfc4;
  --teal-d:   #1a9990;
  --rose:     #e06b7d;
  --text:     #eef0f6;
  --muted:    #8892aa;
  --hint:     #555e78;
  --r-lg:     16px;
  --r-xl:     22px;
  --r-pill:   999px;
  --glow-a:   0 0 28px rgba(232,168,76,0.18);
  --glow-t:   0 0 28px rgba(62,207,196,0.15);
}

/* ── Global reset & base ── */
*, *::before, *::after { box-sizing: border-box; }

html, body, .stApp {
  font-family: 'Outfit', sans-serif !important;
  color: var(--text) !important;
}

.stApp {
  background:
    radial-gradient(ellipse 900px 600px at 0% 0%, rgba(62,207,196,0.07) 0%, transparent 60%),
    radial-gradient(ellipse 700px 500px at 100% 100%, rgba(232,168,76,0.09) 0%, transparent 55%),
    radial-gradient(ellipse 500px 400px at 80% 10%, rgba(224,107,125,0.05) 0%, transparent 50%),
    var(--night) !important;
  min-height: 100vh;
}

/* ── Typography overrides ── */
h1, h2, h3, h4, h5, h6 {
  font-family: 'Cormorant Garamond', serif !important;
  color: var(--text) !important;
  font-weight: 300 !important;
  letter-spacing: -0.01em;
}
p, label, span, div, li, td, th {
  font-family: 'Outfit', sans-serif !important;
  color: var(--text) !important;
}

/* ── Block container ── */
.block-container {
  padding-top: 1rem !important;
  padding-bottom: 9rem !important;
  max-width: 1300px !important;
}

/* ── Streamlit element resets ── */
[data-testid="stMarkdownContainer"] p,
[data-testid="stMarkdownContainer"] li,
[data-testid="stMarkdownContainer"] span,
[data-testid="stText"],
[data-testid="stCaptionContainer"],
[data-testid="stChatMessageContent"] {
  color: var(--text) !important;
  font-family: 'Outfit', sans-serif !important;
}

/* ── Sidebar ── */
[data-testid="stSidebar"] {
  background: var(--night2) !important;
  border-right: 1px solid var(--rim2) !important;
}
[data-testid="stSidebar"] > div:first-child {
  padding: 1.5rem 1.2rem !important;
}
[data-testid="stSidebar"] * {
  color: var(--text) !important;
  font-family: 'Outfit', sans-serif !important;
}
[data-testid="stSidebar"] [data-testid="stMarkdownContainer"] p {
  font-size: 0.82rem;
  color: var(--muted) !important;
}

/* Sidebar section header */
.sidebar-section-title {
  font-family: 'Cormorant Garamond', serif !important;
  font-size: 1.35rem;
  font-weight: 300;
  color: var(--amber2) !important;
  margin: 0 0 1.1rem;
  padding-bottom: 0.6rem;
  border-bottom: 1px solid var(--rim2);
  letter-spacing: 0.01em;
}

/* Slider labels */
[data-testid="stSlider"] label,
[data-testid="stNumberInput"] label {
  font-size: 0.78rem !important;
  font-weight: 500 !important;
  letter-spacing: 0.06em !important;
  text-transform: uppercase !important;
  color: var(--muted) !important;
}

/* Sliders */
[data-testid="stSlider"] [data-baseweb="slider"] div[role="slider"] {
  background: var(--amber) !important;
  border-color: var(--amber) !important;
  box-shadow: var(--glow-a) !important;
}
[data-testid="stSlider"] [data-baseweb="slider"] [data-testid="stTickBar"] + div > div {
  background: linear-gradient(90deg, var(--amber-d), var(--amber)) !important;
}

/* Number input */
[data-testid="stNumberInput"] input {
  background: var(--panel) !important;
  border: 1px solid var(--rim2) !important;
  color: var(--text) !important;
  border-radius: var(--r-lg) !important;
  font-family: 'Outfit', sans-serif !important;
}
[data-testid="stNumberInput"] input:focus {
  border-color: var(--amber) !important;
  box-shadow: var(--glow-a) !important;
}

/* Sidebar divider */
[data-testid="stSidebar"] hr {
  border-color: var(--rim2) !important;
  margin: 1rem 0 !important;
}

/* ── Save button ── */
[data-testid="stButton"] > button {
  background: linear-gradient(135deg, var(--amber-d), var(--amber)) !important;
  color: var(--night) !important;
  border: none !important;
  border-radius: var(--r-pill) !important;
  font-family: 'Outfit', sans-serif !important;
  font-weight: 600 !important;
  font-size: 0.85rem !important;
  letter-spacing: 0.04em !important;
  padding: 0.55rem 1.4rem !important;
  width: 100% !important;
  transition: filter 0.2s, transform 0.15s !important;
  box-shadow: var(--glow-a) !important;
}
[data-testid="stButton"] > button:hover {
  filter: brightness(1.12) !important;
  transform: translateY(-1px) !important;
}
[data-testid="stButton"] > button:active {
  transform: translateY(0) scale(0.98) !important;
}

/* ── Success toast ── */
[data-testid="stAlert"] {
  background: rgba(62,207,196,0.1) !important;
  border: 1px solid rgba(62,207,196,0.3) !important;
  border-radius: var(--r-lg) !important;
  color: var(--teal) !important;
}

/* ── Chat messages ── */
[data-testid="stChatMessage"] {
  background: transparent !important;
  border: none !important;
  padding: 0 !important;
  margin-bottom: 0.6rem !important;
}

/* ── Chat input ── */
[data-testid="stChatInput"] {
  background: var(--panel) !important;
  border: 1px solid var(--rim2) !important;
  border-radius: var(--r-xl) !important;
  box-shadow: 0 8px 32px rgba(0,0,0,0.4) !important;
}
[data-testid="stChatInput"]:focus-within {
  border-color: var(--amber) !important;
  box-shadow: var(--glow-a), 0 8px 32px rgba(0,0,0,0.4) !important;
}
[data-testid="stChatInput"] textarea {
  background: transparent !important;
  color: var(--text) !important;
  font-family: 'Outfit', sans-serif !important;
  font-size: 0.95rem !important;
}
[data-testid="stChatInput"] textarea::placeholder {
  color: var(--hint) !important;
}
[data-testid="stChatInput"] button {
  background: var(--amber) !important;
  border-radius: 50% !important;
  color: var(--night) !important;
}

/* ── Spinner ── */
[data-testid="stSpinner"] * { color: var(--amber) !important; }

/* ── Scrollbar ── */
::-webkit-scrollbar { width: 5px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--rim2); border-radius: 99px; }

/* ── Custom components ── */

/* Top banner */
.arise-banner {
  position: relative;
  overflow: hidden;
  background: linear-gradient(135deg, var(--panel) 0%, var(--panel2) 100%);
  border: 1px solid var(--rim2);
  border-radius: var(--r-xl);
  padding: 1.4rem 1.6rem;
  margin-bottom: 1.1rem;
  box-shadow: 0 16px 48px rgba(0,0,0,0.35);
}
.arise-banner::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(120deg, rgba(232,168,76,0.08) 0%, rgba(62,207,196,0.06) 100%);
  pointer-events: none;
}
.arise-banner::after {
  content: '';
  position: absolute;
  top: -40px; right: -40px;
  width: 180px; height: 180px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(232,168,76,0.12) 0%, transparent 70%);
  pointer-events: none;
}
.arise-banner h2 {
  font-family: 'Cormorant Garamond', serif !important;
  font-size: 2rem !important;
  font-weight: 300 !important;
  color: var(--amber2) !important;
  margin: 0 0 0.2rem !important;
  letter-spacing: -0.02em;
}
.arise-banner p {
  font-size: 0.88rem;
  color: var(--muted) !important;
  margin: 0 !important;
  font-weight: 300;
}
.arise-banner .moon-icon {
  position: absolute;
  top: 1.2rem; right: 1.6rem;
  font-size: 2.4rem;
  opacity: 0.55;
  filter: drop-shadow(0 0 12px var(--amber));
  animation: moon-float 4s ease-in-out infinite;
}
@keyframes moon-float {
  0%,100% { transform: translateY(0); }
  50%      { transform: translateY(-6px); }
}

/* Stat row */
.stat-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0.7rem;
  margin-bottom: 1.1rem;
}
@media (max-width: 768px) {
  .stat-row { grid-template-columns: 1fr; }
}
.stat-card {
  background: var(--panel);
  border: 1px solid var(--rim);
  border-radius: var(--r-lg);
  padding: 0.9rem 1.1rem;
  position: relative;
  overflow: hidden;
  transition: border-color 0.25s, transform 0.2s;
}
.stat-card:hover {
  border-color: var(--rim2);
  transform: translateY(-2px);
}
.stat-card::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0;
  height: 2px;
  border-radius: var(--r-lg) var(--r-lg) 0 0;
}
.stat-card.sleep::before  { background: linear-gradient(90deg, var(--teal-d), var(--teal)); }
.stat-card.energy::before { background: linear-gradient(90deg, var(--amber-d), var(--amber)); }
.stat-card.stress::before { background: linear-gradient(90deg, #a0365f, var(--rose)); }
.stat-label {
  font-size: 0.72rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--muted) !important;
  margin-bottom: 0.3rem;
}
.stat-label.sleep  { color: var(--teal)  !important; }
.stat-label.energy { color: var(--amber) !important; }
.stat-label.stress { color: var(--rose)  !important; }
.stat-value {
  font-family: 'Cormorant Garamond', serif !important;
  font-size: 2rem;
  font-weight: 300;
  color: var(--text) !important;
  line-height: 1;
}
.stat-unit {
  font-size: 0.75rem;
  color: var(--muted) !important;
  margin-top: 0.15rem;
  font-weight: 300;
}

/* Bubbles */
.assistant-bubble, .user-bubble {
  display: block;
  border-radius: var(--r-lg);
  padding: 0.85rem 1.1rem;
  font-size: 0.93rem;
  line-height: 1.65;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  max-width: 82%;
  animation: bubble-in 0.3s ease both;
}
@keyframes bubble-in {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}
.assistant-bubble {
  background: var(--panel);
  border: 1px solid var(--rim2);
  color: var(--text) !important;
  border-bottom-left-radius: 4px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.25);
}
.user-bubble {
  background: linear-gradient(135deg, var(--amber-d), var(--amber));
  color: var(--night) !important;
  border-bottom-right-radius: 4px;
  margin-left: auto;
  font-weight: 500;
  box-shadow: var(--glow-a), 0 4px 20px rgba(0,0,0,0.2);
}
.user-bubble * { color: var(--night) !important; }

/* Message wrapper alignment */
.msg-wrap-user { display: flex; justify-content: flex-end; }
.msg-wrap-ai   { display: flex; justify-content: flex-start; }
</style>
""", unsafe_allow_html=True)

# ── Session state ──────────────────────────────────────────────
if "messages" not in st.session_state:
    st.session_state.messages = [
        {
            "role": "assistant",
            "content": "I am Arise. Tell me how your day is going, and I will respond with mood-aware guidance.",
        }
    ]

data = load_user_data()

# ── Sidebar ────────────────────────────────────────────────────
with st.sidebar:
    st.markdown('<p class="sidebar-section-title">Daily Wellness Log</p>', unsafe_allow_html=True)

    sleep = st.number_input("Sleep Hours", min_value=0.0, max_value=24.0, value=7.0, step=0.5)
    energy = st.slider("Energy Level", 1, 5, 3)
    stress = st.slider("Stress Level", 1, 5, 2)
    mood   = st.slider("Mood Today",   1, 5, 3)

    st.markdown("<br>", unsafe_allow_html=True)

    if st.button("Save Today's Entry", use_container_width=True):
        new_row = {
            "sleep_hours":  sleep,
            "energy_level": energy,
            "stress_level": stress,
            "mood_today":   mood,
        }
        data = pd.concat([data, pd.DataFrame([new_row])], ignore_index=True)
        save_user_data(data)
        st.success("Entry saved.")

    st.markdown("---")
    st.caption("Your recent entries personalise every reply from Arise.")

# ── Banner ─────────────────────────────────────────────────────
st.markdown("""
<div class="arise-banner">
  <span class="moon-icon">🌙</span>
  <h2>Arise</h2>
  <p>Personal reflection, mood support &amp; practical next-step coaching</p>
</div>
""", unsafe_allow_html=True)

# ── Stat cards ─────────────────────────────────────────────────
if not data.empty:
    latest = data.tail(1).iloc[0]
    sl = latest.get('sleep_hours', '—')
    en = latest.get('energy_level', '—')
    st_ = latest.get('stress_level', '—')
    st.markdown(f"""
    <div class="stat-row">
      <div class="stat-card sleep">
        <div class="stat-label sleep">Sleep</div>
        <div class="stat-value">{sl}</div>
        <div class="stat-unit">hours last night</div>
      </div>
      <div class="stat-card energy">
        <div class="stat-label energy">Energy</div>
        <div class="stat-value">{en}<span style="font-size:1rem;color:var(--muted)">/5</span></div>
        <div class="stat-unit">current level</div>
      </div>
      <div class="stat-card stress">
        <div class="stat-label stress">Stress</div>
        <div class="stat-value">{st_}<span style="font-size:1rem;color:var(--muted)">/5</span></div>
        <div class="stat-unit">current level</div>
      </div>
    </div>
    """, unsafe_allow_html=True)

# ── Chat history ───────────────────────────────────────────────
for message in st.session_state.messages:
    with st.chat_message(message["role"], avatar="🌙" if message["role"] == "assistant" else "🧑"):
        safe_msg = escape(message["content"]).replace("\n", "<br>")
        bubble_class = "assistant-bubble" if message["role"] == "assistant" else "user-bubble"
        wrap_class   = "msg-wrap-ai"       if message["role"] == "assistant" else "msg-wrap-user"
        st.markdown(
            f'<div class="{wrap_class}"><div class="{bubble_class}">{safe_msg}</div></div>',
            unsafe_allow_html=True
        )

# ── Chat input ─────────────────────────────────────────────────
prompt = st.chat_input("Share what's on your mind…")
if prompt:
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user", avatar="🧑"):
        safe_p = escape(prompt).replace("\n", "<br>")
        st.markdown(
            f'<div class="msg-wrap-user"><div class="user-bubble">{safe_p}</div></div>',
            unsafe_allow_html=True
        )

    user_summary = data.tail(5).to_dict(orient="records") if not data.empty else []
    with st.chat_message("assistant", avatar="🌙"):
        with st.spinner("Thinking…"):
            reply = generate_response(prompt, user_summary)
        safe_reply = escape(reply).replace("\n", "<br>")
        st.markdown(
            f'<div class="msg-wrap-ai"><div class="assistant-bubble">{safe_reply}</div></div>',
            unsafe_allow_html=True
        )

    st.session_state.messages.append({"role": "assistant", "content": reply})