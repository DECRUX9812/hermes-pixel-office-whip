/**
 * Pixel Office — TUI dock widget.
 *
 * Ambient card docked above the status bar: live agent roster + whip stats,
 * polled from the office HTTP server every 3s. Toggle with /office.
 */

export default function register(sdk) {
  const { Box, Text, Dialog, defineWidgetApp, h } = sdk
  const React = sdk.React

  const URL = 'http://127.0.0.1:8113/state'

  function statusColor(t, status) {
    switch (status) {
      case 'working': return t.color.primary
      case 'thinking': return t.color.ok
      case 'waiting': return t.color.error
      default: return t.color.muted
    }
  }

  function useOffice() {
    const [snap, setSnap] = React.useState(null)
    const [err, setErr] = React.useState(null)
    React.useEffect(() => {
      let dead = false
      const tick = () => {
        try {
          fetch(URL, { cache: 'no-store' })
            .then(r => r.json())
            .then(d => { if (!dead) { setSnap(d); setErr(null) } })
            .catch(e => { if (!dead) setErr(String(e.message || e)) })
        } catch (e) {
          if (!dead) setErr(String(e.message || e))
        }
      }
      tick()
      const iv = setInterval(tick, 3000)
      return () => { dead = true; clearInterval(iv) }
    }, [])
    return [snap, err]
  }

  function OfficeCard({ t }) {
    const [snap, err] = useOffice()

    if (err) {
      return h(Dialog, { width: 36 },
        h(Text, { color: t.color.error }, 'PIXEL OFFICE: unreachable'))
    }
    if (!snap) {
      return h(Dialog, { width: 36 },
        h(Text, { color: t.color.muted }, 'PIXEL OFFICE: loading…'))
    }

    const agents = (snap.agents || []).slice(0, 4)
    const whip = snap.whip || { count: 0, last: null }
    const rows = agents.map(a => h(Box, { key: a.id },
      h(Text, { color: statusColor(t, a.status) }, '● '),
      h(Text, { color: t.color.label }, String(a.label || '').slice(0, 20).padEnd(20)),
      h(Text, { color: t.color.muted }, ' ' + String(a.status || 'idle').padEnd(8)),
      a.tool ? h(Text, { color: t.color.muted }, String(a.tool).slice(0, 0)) : null
    ))

    const children = [
      h(Text, { key: 'hdr', color: t.color.primary, bold: true }, 'PIXEL OFFICE'),
      ...rows,
      h(Text, { key: 'foot', color: t.color.muted },
        String(snap.agents.length).padStart(2) + ' agents · ' +
        String(whip.count).padStart(2) + ' whips')
    ]
    if (whip.last && whip.last.line) {
      children.push(h(Text, { key: 'last', color: t.color.muted, wrap: 'truncate-end' },
        '💥 ' + String(whip.last.line).slice(0, 33)))
    }
    return h(Dialog, { width: 36 }, ...children)
  }

  defineWidgetApp({
    id: 'office',
    help: 'live agent office + whip count',
    mode: 'ambient',
    zone: 'bottom-right',
    init: () => ({}),
    reduce: (state, { ch, key }) => (key.escape || ch === 'q' ? null : state),
    render: ({ t }) => h(OfficeCard, { t })
  })
}
