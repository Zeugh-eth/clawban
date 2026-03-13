export default async function handler(req, res) {
  try {
    const r = await fetch('http://178.156.223.153:18793/api/activity');
    const data = await r.json();
    res.setHeader('Cache-Control', 'no-cache');
    res.json(data);
  } catch (e) {
    res.status(502).json({ error: 'Backend unreachable' });
  }
}
