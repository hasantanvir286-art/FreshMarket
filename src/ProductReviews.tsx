import { useEffect, useState } from 'react';
import { Star, X } from 'lucide-react';
import type { Product } from './data';
import { supabase } from './supabase';

type Review = { id: string; customer_display_name: string; rating: number; review_text: string; created_at: string };
const money = (n: number) => `৳${n.toLocaleString('en-BD', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

export function ProductReviews({ product, onClose, onOpenAccount, onRatingUpdate }: {
  product: Product;
  onClose: () => void;
  onOpenAccount: () => void;
  onRatingUpdate: (productId: string, rating: number, count: number) => void;
}) {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [session, setSession] = useState<any>(null);
  const [rating, setRating] = useState(5);
  const [reviewText, setReviewText] = useState('');
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (!supabase) { setLoading(false); return; }
    let alive = true;
    const loadReviews = async () => {
      const { data, error } = await supabase!.from('reviews').select('id,customer_display_name,rating,review_text,created_at').eq('product_id', product.id).eq('moderation_status', 'approved').order('created_at', { ascending: false });
      if (!alive) return;
      if (!error) {
        const rows = (data || []) as Review[];
        setReviews(rows.slice(0, 50));
        const count = rows.length;
        const average = count ? rows.reduce((sum, review) => sum + review.rating, 0) / count : 0;
        onRatingUpdate(product.id, average, count);
      }
      setLoading(false);
    };
    void supabase.auth.getSession().then(({ data }) => { if (alive) setSession(data.session); });
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, next) => { if (alive) setSession(next); });
    void loadReviews();
    return () => { alive = false; subscription.unsubscribe(); };
  }, [product.id]);

  async function submitReview(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!supabase || !session) { onOpenAccount(); return; }
    if (reviewText.trim().length < 5) { setMessage('Please write at least 5 characters.'); return; }
    setBusy(true); setMessage('');
    const { error } = await supabase.rpc('submit_verified_product_review', {
      p_product_id: product.id,
      p_rating: rating,
      p_review_text: reviewText.trim(),
    });
    if (error) {
      const detail = error.message.toLowerCase();
      setMessage(detail.includes('function') || detail.includes('submit_verified_product_review')
        ? 'Review submission is not enabled yet. Run migration 202610180003_verified_product_reviews.sql in Supabase SQL Editor.'
        : detail.includes('delivered order')
          ? 'You can review this product after a signed-in order containing it has been delivered.'
          : error.message);
      setBusy(false);
      return;
    }
    setReviewText('');
    const { data } = await supabase.from('reviews').select('id,customer_display_name,rating,review_text,created_at').eq('product_id', product.id).eq('moderation_status', 'approved').order('created_at', { ascending: false });
    const rows = (data || []) as Review[];
    setReviews(rows.slice(0, 50));
    const count = rows.length;
    onRatingUpdate(product.id, count ? rows.reduce((sum, review) => sum + review.rating, 0) / count : 0, count);
    setBusy(false);
    setMessage('Thanks! Your verified review has been published.');
  }

  return <div className="checkout-overlay product-review-overlay" onMouseDown={event => { if (event.target === event.currentTarget) onClose(); }}>
    <section className="product-review-dialog" role="dialog" aria-modal="true" aria-labelledby="product-review-title">
      <header className="product-review-header"><span>PRODUCT DETAILS & REVIEWS</span><button type="button" className="icon-btn" onClick={onClose} aria-label="Close product details"><X/></button></header>
      <div className="product-review-product"><img src={product.image} alt={product.name}/><div><small>{product.category}</small><h2 id="product-review-title">{product.name}</h2><p>{product.unit}</p><strong>{money(product.price)}</strong><span className="product-review-average"><Star size={16} fill="currentColor"/> {product.rating.toFixed(1)} <small>({product.reviews} reviews)</small></span></div></div>
      <div className="product-review-columns"><section className="product-review-list"><h3>Customer reviews <span>{product.reviews}</span></h3>{loading ? <p className="product-review-empty">Loading reviews…</p> : reviews.length ? reviews.map(review => <article key={review.id} className="product-review-item"><div><b>{review.customer_display_name}</b><span className="product-review-stars" aria-label={`${review.rating} out of 5 stars`}>{Array.from({ length: 5 }, (_, index) => <Star key={index} size={13} fill={index < review.rating ? 'currentColor' : 'none'}/>)}</span></div><small>{new Date(review.created_at).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' })}</small><p>{review.review_text}</p></article>) : <p className="product-review-empty">No reviews yet. Delivered customers can be the first to share their experience.</p>}</section>
        <section className="product-review-form-panel"><h3>Rate this product</h3><p>Reviews are available to signed-in customers after delivery.</p>{session ? <form onSubmit={submitReview}><fieldset disabled={busy}><legend>Your rating</legend><div className="product-rating-picker" role="radiogroup" aria-label="Choose a rating">{[1, 2, 3, 4, 5].map(value => <button key={value} type="button" role="radio" aria-checked={rating === value} aria-label={`${value} star${value === 1 ? '' : 's'}`} onClick={() => setRating(value)}><Star size={25} fill={value <= rating ? 'currentColor' : 'none'}/></button>)}</div><label>Your review<textarea value={reviewText} onChange={event => setReviewText(event.target.value)} minLength={5} maxLength={1000} rows={5} placeholder="What did you think of this product?" required/></label><small>Only customers with a delivered order can publish a review.</small><button className="btn primary full" disabled={busy}>{busy ? 'Submitting…' : 'Submit review'}</button></fieldset></form> : <button className="btn primary full" onClick={onOpenAccount}>Sign in to leave a review</button>}{message && <div className={message.startsWith('Thanks') ? 'account-message' : 'checkout-error'} role="status">{message}</div>}</section>
      </div>
    </section>
  </div>;
}
