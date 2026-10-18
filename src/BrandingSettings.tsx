import { useEffect, useState } from 'react';
import { Check, ImagePlus } from 'lucide-react';
import { supabase } from './supabase';

export type StoreBrand = { name: string; logo_url: string };
export const DEFAULT_STORE_BRAND: StoreBrand = { name: 'Fresh Market', logo_url: '' };

export function BrandingSettings({ brand, onSaved }: { brand: StoreBrand; onSaved: (brand: StoreBrand) => void }) {
  const [name, setName] = useState(brand.name);
  const [logoUrl, setLogoUrl] = useState(brand.logo_url);
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [previousBrand, setPreviousBrand] = useState<StoreBrand | null>(null);

  useEffect(() => { setName(brand.name); setLogoUrl(brand.logo_url); }, [brand.name, brand.logo_url]);
  useEffect(() => {
    if (!supabase) return;
    let live = true;
    void supabase.from('store_settings').select('value').eq('key', 'store_brand').maybeSingle().then(({ data }) => {
      if (!live || !data?.value) return;
      const previous = (data.value as { previous?: Partial<StoreBrand> }).previous;
      if (previous && typeof previous.name === 'string' && typeof previous.logo_url === 'string') setPreviousBrand({ name: previous.name, logo_url: previous.logo_url });
    });
    return () => { live = false; };
  }, []);

  function chooseFile(next?: File) {
    setFile(next || null);
    setPreview('');
    if (!next) return;
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(next.type)) { setError('Choose a JPG, PNG, or WebP logo.'); setFile(null); return; }
    if (next.size > 5 * 1024 * 1024) { setError('Choose a logo smaller than 5 MB.'); setFile(null); return; }
    const reader = new FileReader(); reader.onload = () => setPreview(String(reader.result || '')); reader.readAsDataURL(next);
    setError(''); setMessage('');
  }

  async function save(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!supabase) { setError('Connect Supabase before saving store branding.'); return; }
    const normalizedName = name.trim();
    if (normalizedName.length < 2 || normalizedName.length > 60) { setError('Store name must be between 2 and 60 characters.'); return; }
    setBusy(true); setError(''); setMessage('');
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) { setBusy(false); setError('Sign in again with your superadmin account to change branding.'); return; }
    let nextLogoUrl = logoUrl;
    if (file) {
      const extension = file.type === 'image/png' ? 'png' : file.type === 'image/webp' ? 'webp' : 'jpg';
      const path = `branding/${crypto.randomUUID()}.${extension}`;
      const { data, error: uploadError } = await supabase.storage.from('store-assets').upload(path, file, { contentType: file.type, cacheControl: '3600' });
      if (uploadError) { setBusy(false); setError(uploadError.message.includes('Bucket not found') ? 'Logo storage is not set up. Run supabase/migrations/202610180004_store_branding.sql in Supabase SQL Editor.' : uploadError.message); return; }
      nextLogoUrl = `${supabase.storage.from('store-assets').getPublicUrl(data.path).data.publicUrl}?v=${Date.now()}`;
    }
    const nextBrand = { name: normalizedName, logo_url: nextLogoUrl, previous: { name: brand.name, logo_url: brand.logo_url } };
    const { error: saveError } = await supabase.from('store_settings').upsert({ key: 'store_brand', value: nextBrand, updated_by: user.id }, { onConflict: 'key' });
    setBusy(false);
    if (saveError) { setError(saveError.message); return; }
    setLogoUrl(nextLogoUrl); setFile(null); setPreview(''); setPreviousBrand({ name: brand.name, logo_url: brand.logo_url }); setMessage('Store name and logo saved.'); onSaved({ name: nextBrand.name, logo_url: nextBrand.logo_url });
  }

  async function restorePrevious() {
    if (!supabase || !previousBrand) return;
    setBusy(true); setError(''); setMessage('');
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) { setBusy(false); setError('Sign in again with your superadmin account to restore branding.'); return; }
    const restored = { ...previousBrand, previous: { name: brand.name, logo_url: brand.logo_url } };
    const { error: saveError } = await supabase.from('store_settings').upsert({ key: 'store_brand', value: restored, updated_by: user.id }, { onConflict: 'key' });
    setBusy(false);
    if (saveError) { setError(saveError.message); return; }
    setName(restored.name); setLogoUrl(restored.logo_url); setFile(null); setPreview(''); setPreviousBrand({ name: brand.name, logo_url: brand.logo_url });
    setMessage('Previous store name and logo restored.'); onSaved({ name: restored.name, logo_url: restored.logo_url });
  }

  return <div className="admin-panel edit-form branding-settings-panel">
    <div className="panel-head"><div><h3>Store name and logo</h3><small>Update the branding shown across your storefront and admin workspace.</small></div></div>
    <form onSubmit={save}>
      <label>Store name<input value={name} onChange={event => setName(event.target.value)} maxLength={60} required placeholder="Fresh Market"/></label>
      <label>Store logo <span className="optional">JPG, PNG, or WebP · max 5 MB</span><input type="file" accept="image/jpeg,image/png,image/webp" onChange={event => { chooseFile(event.currentTarget.files?.[0]); event.currentTarget.value = ''; }}/></label>
      {(preview || logoUrl) ? <div className="branding-preview"><img src={preview || logoUrl} alt="Store logo preview"/><span>Logo preview</span><button type="button" className="btn outline" onClick={() => { setLogoUrl(''); setFile(null); setPreview(''); }}>Remove logo</button></div> : <div className="branding-empty"><ImagePlus size={22}/><span>No custom logo uploaded. The Fresh Market leaf mark will be used.</span></div>}
      {error && <div className="checkout-error" role="alert">{error}</div>}{message && <div className="account-message" role="status">{message}</div>}
      <div className="form-actions"><button className="btn primary" disabled={busy}>{busy ? 'Saving…' : 'Save store branding'} <Check size={15}/></button>{previousBrand && (previousBrand.name !== brand.name || previousBrand.logo_url !== brand.logo_url) && <button type="button" className="btn outline" disabled={busy} onClick={() => void restorePrevious()}>Restore previous branding</button>}</div>
    </form>
  </div>;
}
