import streamlit as st

# -----------------------------
# Page Configuration
# -----------------------------
st.set_page_config(
    page_title="K3s CI/CD Demo",
    page_icon="🚀",
    layout="wide"
)

# -----------------------------
# Sidebar Navigation
# -----------------------------
menu = st.sidebar.selectbox(
    "Navigation",
    ["Home", "Dashboard", "About"]
)

st.sidebar.markdown("---")
st.sidebar.success("🚀 Deployed via Jenkins CI/CD Pipeline")
st.sidebar.success("App - Version - 3.0")
st.sidebar.info("Kubernetes Cluster: K3s")

# -----------------------------
# Home Page
# -----------------------------
if menu == "Home":
    st.title("🚀 Streamlit on Kubernetes (K3s)")
    st.success("Application successfully deployed inside a Kubernetes Pod")

    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Environment")
        st.write("✔ Containerized Application")
        st.write("✔ Running in Kubernetes")
        st.write("✔ Automated Deployment")
        st.write("✔ CI/CD Powered by Jenkins")

    with col2:
        st.subheader("Status")
        st.metric("Deployment Version", "3.0")
        st.metric("Cluster Type", "K3s")
        st.metric("Pipeline Status", "SUCCESS")

    st.balloons()

# -----------------------------
# Dashboard Page
# -----------------------------
elif menu == "Dashboard":
    st.title("📊 Deployment Dashboard")

    st.info("Sample runtime metrics for demo purposes")

    col1, col2, col3 = st.columns(3)

    col1.metric("Pods Running", "1")
    col2.metric("CPU Usage", "Low")
    col3.metric("Memory Usage", "Stable")

    st.progress(90)
    st.caption("System operating normally")

# -----------------------------
# About Page
# -----------------------------
elif menu == "About":
    st.title("ℹ️ About This Demo")

    st.markdown("""
This application demonstrates a **fully automated CI/CD pipeline**:

- Source Code → GitHub  
- Build → Jenkins Pipeline - JCasC & DSL  
- Container → Docker  
- Deployment → Kubernetes (K3s)  

Everything is provisioned automatically using Infrastructure as Code.
    """)

    st.success("Automation eliminates manual deployment steps ✔")

# -----------------------------
# Footer
# -----------------------------
st.markdown("---")
st.caption("DevOps Automation Demo • Streamlit + Jenkins + Kubernetes")
