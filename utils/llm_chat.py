from statistics import mean

try:
    from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
except ImportError:
    raise ImportError(
        "transformers not found. Install with: pip install transformers torch"
    )


def _safe_float(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _safe_mean(values):
    numeric = [v for v in (_safe_float(item) for item in values) if v is not None]
    return round(mean(numeric), 2) if numeric else None


def _latest_metrics(user_data_summary):
    if not user_data_summary:
        return {}
    return user_data_summary[-1] if isinstance(user_data_summary[-1], dict) else {}


def _build_context(user_data_summary):
    """Build mood/wellness context from user data for prompt."""
    if not user_data_summary:
        return ""

    latest = _latest_metrics(user_data_summary)
    
    sleep = _safe_float(latest.get("sleep_hours"))
    energy = _safe_float(latest.get("energy_level"))
    stress = _safe_float(latest.get("stress_level"))
    mood = _safe_float(latest.get("mood_today"))

    context_parts = []
    if sleep is not None:
        context_parts.append(f"recent sleep: {sleep} hours")
    if energy is not None:
        context_parts.append(f"current energy: {energy}/5")
    if stress is not None:
        context_parts.append(f"current stress: {stress}/5")
    if mood is not None:
        context_parts.append(f"mood: {mood}/5")

    if context_parts:
        return f"User context: {', '.join(context_parts)}."
    return ""


def generate_response(user_message, user_data_summary):
    """Generate response using flan-t5-small local model with mood context."""
    try:
        import streamlit as st
        
        # Load model and tokenizer once per session
        if "model" not in st.session_state:
            with st.spinner("Loading AI model..."):
                st.session_state.model = AutoModelForSeq2SeqLM.from_pretrained(
                    "google/flan-t5-small"
                )
                st.session_state.tokenizer = AutoTokenizer.from_pretrained(
                    "google/flan-t5-small"
                )
        
        model = st.session_state.model
        tokenizer = st.session_state.tokenizer
    except Exception:
        # Fallback if Streamlit not available (e.g., in testing)
        model = AutoModelForSeq2SeqLM.from_pretrained("google/flan-t5-small")
        tokenizer = AutoTokenizer.from_pretrained("google/flan-t5-small")

    text = (user_message or "").strip()
    if not text:
        return "Tell me how you are feeling right now, and I will help you."

    # Build context from user mood data
    context = _build_context(user_data_summary)

    # Create instruction prompt for the model
    prompt = (
        f"You are Arise, a warm, supportive personal wellness assistant. "
        f"You give practical, actionable advice in 2-3 concise sentences. "
        f"{context} "
        f"User says: {text} "
        f"Your response:"
    )

    # Generate response
    try:
        inputs = tokenizer(prompt, return_tensors="pt", max_length=512, truncation=True)
        outputs = model.generate(
            **inputs,
            max_length=150,
            min_length=20,
            do_sample=True,
            temperature=0.8,
            top_p=0.95,
        )
        response = tokenizer.decode(outputs[0], skip_special_tokens=True).strip()
        return response if response else "I'm here to help. Tell me more about what you need."
    except Exception as e:
        return f"I am having a moment. Please try again: {str(e)}"