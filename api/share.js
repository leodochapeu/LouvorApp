const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const MONTHS = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

const WEEKDAYS = [
  'domingo',
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
];

const SITE = 'Louvor App';
const HOME_DESCRIPTION = 'Cifras, letras e setlists de louvor para o culto.';

module.exports = async function handler(req, res) {
  const origin = requestOrigin(req);
  const kind = String(req.query.kind || 'home');
  const slug = String(req.query.slug || '').trim();
  const preview = await resolvePreview(kind, slug);

  const url = canonicalUrl(origin, kind, slug, preview.canonicalSlug);
  const html = renderHtml({
    origin,
    url,
    title: preview.title,
    description: preview.description,
  });

  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'public, s-maxage=300, stale-while-revalidate=86400');
  res.status(200).send(html);
};

function requestOrigin(req) {
  const host = req.headers['x-forwarded-host'] || req.headers.host || 'localhost';
  const proto = req.headers['x-forwarded-proto'] || 'https';
  return `${proto}://${host}`;
}

function canonicalUrl(origin, kind, slug, canonicalSlug) {
  const pathSlug = canonicalSlug || slug;
  if (kind === 'song' && pathSlug) return `${origin}/songs/${pathSlug}`;
  if (kind === 'culto' && pathSlug) return `${origin}/culto/${pathSlug}`;
  if (kind === 'cultos') return `${origin}/cultos`;
  return `${origin}/`;
}

async function resolvePreview(kind, slug) {
  if (kind === 'song' && slug && slug !== 'new') {
    const song = await fetchRow('songs', slug);
    if (song) {
      const authors = Array.isArray(song.authors)
        ? song.authors.map((author) => String(author).trim()).filter(Boolean)
        : [];
      let description = `Cifra e letra de ${song.title}`;
      if (authors.length) description += `, de ${authors.join(', ')}`;
      const key = String(song.original_key || '').trim();
      if (key) description += `. Tom original: ${key}`;
      description += '.';
      return {
        title: `${song.title} · ${SITE}`,
        description,
        canonicalSlug: song.slug || slug,
      };
    }
  }

  if (kind === 'culto' && slug && slug !== 'new') {
    const culto = await fetchRow('cultos', slug);
    if (culto) {
      const songIds = Array.isArray(culto.song_ids) ? culto.song_ids : [];
      const countLabel =
        songIds.length === 1 ? '1 música' : `${songIds.length} músicas`;
      const when = formatLongDate(culto.service_date);
      return {
        title: `${culto.title} · ${SITE}`,
        description: `Setlist de ${culto.title} · ${when} · ${countLabel}.`,
        canonicalSlug: culto.slug || slug,
      };
    }
  }

  if (kind === 'cultos') {
    return {
      title: `Cultos · ${SITE}`,
      description: 'Setlists dos cultos, com cifras e letras.',
    };
  }

  return {
    title: SITE,
    description: HOME_DESCRIPTION,
  };
}

async function fetchRow(table, slug) {
  const base = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_ANON_KEY;
  if (!base || !key || !slug) return null;

  const id = idFromSlug(slug);
  const filter = id
    ? `id=eq.${encodeURIComponent(id)}`
    : `slug=eq.${encodeURIComponent(slug)}`;
  const url = `${base.replace(/\/$/, '')}/rest/v1/${table}?${filter}&select=*&limit=1`;

  try {
    const response = await fetch(url, {
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
      },
    });
    if (!response.ok) return null;
    const rows = await response.json();
    return Array.isArray(rows) ? rows[0] : null;
  } catch {
    return null;
  }
}

function idFromSlug(slug) {
  const value = String(slug);
  if (UUID_RE.test(value)) return value;
  const atEnd = value.match(
    /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
  );
  return atEnd ? atEnd[0] : null;
}

function formatLongDate(raw) {
  if (!raw) return '';
  const date = new Date(`${String(raw).slice(0, 10)}T00:00:00`);
  if (Number.isNaN(date.getTime())) return String(raw);
  const weekday = WEEKDAYS[date.getDay()];
  const month = MONTHS[date.getMonth()];
  return `${weekday}, ${date.getDate()} de ${month} de ${date.getFullYear()}`;
}

function renderHtml({ origin, url, title, description }) {
  const image = `${origin}/icons/Icon-512.png`;
  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>${esc(title)}</title>
  <meta name="description" content="${esc(description)}">
  <meta property="og:site_name" content="${esc(SITE)}">
  <meta property="og:title" content="${esc(title)}">
  <meta property="og:description" content="${esc(description)}">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:url" content="${esc(url)}">
  <meta property="og:image" content="${esc(image)}">
  <meta name="twitter:card" content="summary">
  <meta name="twitter:title" content="${esc(title)}">
  <meta name="twitter:description" content="${esc(description)}">
  <meta name="twitter:image" content="${esc(image)}">
  <link rel="icon" type="image/png" href="/favicon.png">
</head>
<body>
  <p>${esc(title)}</p>
  <p>${esc(description)}</p>
</body>
</html>`;
}

function esc(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
