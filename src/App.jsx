export default function App() {
  return (
    <div className="page">
      <header>
        <h1>Boudreaux Labs</h1>
        <p className="subtitle">Platform Engineering</p>
      </header>

      <main>
        <div className="card">
          <div className="flame">🔥</div>
          <h2>The lab is dark.</h2>
          <p>
            Boudreaux Labs is a phoenix environment &mdash; built to be destroyed.
            If you&apos;re seeing this, it was recently burnt down to save a buck.
            Don&apos;t worry, it&apos;ll come back to life when Mr. Boudreaux needs it.
          </p>
        </div>

        <div className="meta">
          <p className="meta-label">While the cluster sleeps, this page is served by:</p>
          <div className="tags">
            <span className="tag">React</span>
            <span className="tag">AWS S3</span>
            <span className="tag">CloudFront</span>
          </div>
        </div>
      </main>

      <footer>
        <a href="https://github.com/boudreaux-labs" target="_blank" rel="noreferrer">
          github.com/boudreaux-labs
        </a>
        <span className="divider">&mdash;</span>
        <span>boudreauxlabs.com</span>
      </footer>
    </div>
  )
}
