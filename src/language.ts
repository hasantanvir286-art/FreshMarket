export type Language = 'en' | 'bn';

const bn: Record<string, string> = {
  'Frozen Foods': 'হিমায়িত খাবার', 'FROZEN FOODS': 'হিমায়িত খাবার', 'FRESHNESS, DELIVERED': 'সতেজতা পৌঁছে যাবে আপনার দরজায়', 'Good food.': 'ভালো খাবার।', 'Good mood.': 'ভালো মন।', 'Every day.': 'প্রতিদিন।',
  'Farm-fresh produce and everyday favorites, delivered to homes across Bangladesh.': 'খামারের তাজা পণ্য ও নিত্যপ্রয়োজনীয় পছন্দের জিনিস সারা বাংলাদেশে পৌঁছে দিই।',
  'Shop fresh today': 'আজই তাজা পণ্য কিনুন', 'Explore this week’s deals': 'এই সপ্তাহের অফার দেখুন', 'Always fresh': 'সবসময় সতেজ', 'Fast delivery': 'দ্রুত ডেলিভারি', 'Goodness guaranteed': 'মানের নিশ্চয়তা',
  'Picked fresh': 'তাজা বেছে নেওয়া', 'for you': 'আপনার জন্য', 'From local farms': 'স্থানীয় খামার থেকে', 'Good things grow nearby': 'ভালো পণ্য কাছেই উৎপাদিত হয়',
  'Free delivery': 'ফ্রি ডেলিভারি', 'On orders over ৳2,500': '৳২,৫০০-এর বেশি অর্ডারে', 'Fresh, always': 'সবসময় সতেজ', 'Picked with care daily': 'প্রতিদিন যত্ন করে বাছাই',
  'Quality promise': 'মানের প্রতিশ্রুতি', "Love it or we'll fix it": 'পছন্দ না হলে আমরা সমাধান করব', 'Nationwide delivery': 'সারা দেশে ডেলিভারি', 'Across Bangladesh': 'সারা বাংলাদেশে',
  'A LITTLE SOMETHING FOR EVERYONE': 'সবার জন্য কিছু না কিছু', 'Shop by': 'ক্যাটাগরি অনুযায়ী', 'category': 'ক্যাটাগরি', 'All categories': 'সব ক্যাটাগরি', 'Explore this category': 'এই ক্যাটাগরি দেখুন',
  'THIS WEEK ONLY': 'শুধু এই সপ্তাহে', 'A little extra': 'আরও একটু', 'in your basket.': 'আপনার ঝুড়িতে।', 'Get free delivery on orders over ৳2,500.': '৳২,৫০০-এর বেশি অর্ডারে ফ্রি ডেলিভারি।', '*While the good stuff lasts.': '*স্টক থাকা পর্যন্ত।',
  'GOOD THINGS ARE GROWING': 'সতেজ পণ্যের মৌসুম চলছে', 'Fresh from': 'সরাসরি', 'the farm.': 'খামার থেকে।', 'Meet this season’s sweetest picks.': 'এই মৌসুমের সেরা পছন্দগুলো দেখুন।', 'Shop seasonal': 'মৌসুমি পণ্য কিনুন',
  'A FRESH TAKE ON YOUR WEEKLY SHOP': 'আপনার সাপ্তাহিক বাজারে নতুন সতেজতা', 'Fresh picks in Bangladesh': 'বাংলাদেশের সেরা তাজা পণ্য', 'Choose a category above to filter products': 'পণ্য ফিল্টার করতে উপরের ক্যাটাগরি বেছে নিন',
  'Loading fresh catalog': 'তাজা পণ্যের তালিকা লোড হচ্ছে', 'Connecting to your store database.': 'আপনার স্টোর ডেটাবেসে সংযোগ হচ্ছে।', 'No fresh finds just yet': 'এখনো কোনো পণ্য পাওয়া যায়নি',
  'Fresh groceries delivered to your door': 'তাজা বাজার পৌঁছে যাবে আপনার দরজায়',
  'special offers every week!': 'প্রতি সপ্তাহে বিশেষ অফার!', 'Shop deals': 'অফার দেখুন',
  'Delivery': 'ডেলিভারি', 'All over Bangladesh': 'সারা বাংলাদেশে', 'Supabase connected': 'সুপাবেস সংযুক্ত',
  'Connecting to Supabase': 'সুপাবেসে সংযোগ হচ্ছে', 'Supabase setup needed': 'সুপাবেস সেটআপ প্রয়োজন',
  'Demo catalog': 'নমুনা পণ্য তালিকা', 'Free delivery on orders over ৳2,500': '৳২,৫০০-এর বেশি অর্ডারে ডেলিভারি ফ্রি',
  'Need help?': 'সাহায্য লাগবে?', 'Account': 'অ্যাকাউন্ট', 'Wishlist': 'পছন্দের তালিকা', 'My cart': 'আমার কার্ট',
  'Browse categories': 'ক্যাটাগরি দেখুন', 'Shop All': 'সব পণ্য', 'Weekly deals': 'সাপ্তাহিক অফার',
  'Shop everything': 'সব পণ্য দেখুন', 'Search fresh produce, pantry staples...': 'তাজা পণ্য ও নিত্যপ্রয়োজনীয় জিনিস খুঁজুন...',
  'Fresh choices, thoughtfully picked. Bringing a little more goodness to your everyday.': 'বেছে নেওয়া সতেজ পণ্য, প্রতিদিনের জীবনে আরও ভালো কিছু নিয়ে আসে।',
  'Fresh Choices. Happier Homes.': 'সতেজ পছন্দ, সুখী পরিবার।', 'Explore': 'ঘুরে দেখুন', 'Shop all': 'সব পণ্য',
  'Fruit & veg': 'ফল ও সবজি', 'Meat & seafood': 'মাংস ও সামুদ্রিক খাবার', 'Dairy & eggs': 'দুগ্ধজাত পণ্য ও ডিম',
  'Here to help': 'আমরা সাহায্যের জন্য আছি', 'Contact us': 'যোগাযোগ করুন', 'Delivery information': 'ডেলিভারির তথ্য',
  'Returns & refunds': 'ফেরত ও টাকা ফেরত', 'FAQs': 'সাধারণ প্রশ্ন', 'Privacy & terms': 'গোপনীয়তা ও শর্তাবলি',
  'Say hello': 'যোগাযোগ করুন', 'Secure checkout': 'নিরাপদ চেকআউট', 'YOUR BAG': 'আপনার ব্যাগ',
  'Shopping basket': 'কেনাকাটার ঝুড়ি', 'Subtotal': 'উপমোট', 'Total': 'সর্বমোট',
  'FREE': 'ফ্রি', 'Continue to secure checkout': 'নিরাপদ চেকআউটে যান', 'Keep browsing': 'কেনাকাটা চালিয়ে যান',
  'Your basket is feeling light': 'আপনার ঝুড়ি এখনো খালি', 'Let’s fill it with some good things.': 'চলুন পছন্দের কিছু পণ্য যোগ করি।',
  'Find your fresh picks': 'পছন্দের তাজা পণ্য দেখুন', 'Delivery details': 'ডেলিভারির তথ্য', 'Choose how to pay': 'পেমেন্ট পদ্ধতি বেছে নিন',
  'Cash on delivery': 'ক্যাশ অন ডেলিভারি', 'Pay when your groceries arrive': 'পণ্য পৌঁছালে পেমেন্ট করুন',
  'Pay online securely': 'নিরাপদে অনলাইনে পেমেন্ট করুন', 'Order summary': 'অর্ডারের সারাংশ', 'Place order': 'অর্ডার করুন',
  'Order received': 'অর্ডার গ্রহণ করা হয়েছে', 'Thanks for shopping': 'কেনাকাটার জন্য ধন্যবাদ', 'Close': 'বন্ধ করুন',
  'Welcome back': 'আবার স্বাগতম', 'Your account': 'আপনার অ্যাকাউন্ট', 'Your orders': 'আপনার অর্ডার',
  'No account orders yet. Orders placed while signed in appear here.': 'এখনো কোনো অর্ডার নেই। লগ ইন থাকা অবস্থায় করা অর্ডার এখানে দেখা যাবে।',
  'Edit profile': 'প্রোফাইল সম্পাদনা', 'Sign out': 'লগ আউট', 'Profile photo': 'প্রোফাইল ছবি',
  'Full name': 'পুরো নাম', 'Phone': 'ফোন', 'Save profile': 'প্রোফাইল সংরক্ষণ', 'Cancel': 'বাতিল',
  'Change password': 'পাসওয়ার্ড পরিবর্তন', 'New password': 'নতুন পাসওয়ার্ড', 'Confirm new password': 'নতুন পাসওয়ার্ড নিশ্চিত করুন',
  'Update password': 'পাসওয়ার্ড আপডেট', 'Sign in': 'লগ ইন', 'Create account': 'অ্যাকাউন্ট তৈরি করুন',
  'Processing': 'প্রক্রিয়াধীন', 'Delivered': 'ডেলিভারি সম্পন্ন', 'Cancelled': 'বাতিল', 'Pending': 'অপেক্ষমাণ',
  'Confirmed': 'নিশ্চিত', 'Order status': 'অর্ডারের অবস্থা', 'Order details': 'অর্ডারের বিবরণ',
  'All groceries': 'সব পণ্য', 'Fruits': 'ফল', 'Vegetables': 'সবজি', 'Meat & Seafood': 'মাংস ও সামুদ্রিক খাবার',
  'Dairy & Eggs': 'দুগ্ধজাত পণ্য ও ডিম', 'Bakery': 'বেকারি', 'Beverages': 'পানীয়', 'Snacks': 'স্ন্যাকস', 'Household': 'গৃহস্থালি',
  'All products': 'সব পণ্য', 'Low stock': 'কম স্টক', 'Out of stock': 'স্টক শেষ', 'Add to cart': 'কার্টে যোগ করুন',
  'Add': 'যোগ করুন', 'Added to cart': 'কার্টে যোগ হয়েছে', 'Sort by': 'সাজান', 'Featured': 'বিশেষ পণ্য',
  'Price: low to high': 'দাম: কম থেকে বেশি', 'Price: high to low': 'দাম: বেশি থেকে কম', 'Name A–Z': 'নাম: অ থেকে য়',
  'On sale': 'ছাড় চলছে', 'Filter': 'ফিল্টার', 'View all': 'সব দেখুন', 'Shop now': 'এখনই কিনুন',
  'Overview': 'সারসংক্ষেপ', 'Orders': 'অর্ডার', 'Customers': 'ক্রেতা', 'Inventory': 'স্টক', 'Reports': 'রিপোর্ট',
  'Products': 'পণ্য', 'Settings': 'সেটিংস', 'Staff': 'কর্মী', 'Coupons': 'কুপন', 'Save changes': 'পরিবর্তন সংরক্ষণ',
  'Refresh': 'রিফ্রেশ', 'Search products...': 'পণ্য খুঁজুন...', 'Search': 'খুঁজুন', 'Payment': 'পেমেন্ট',
  'Order received successfully.': 'অর্ডার সফলভাবে গ্রহণ করা হয়েছে।', 'Thank you for shopping with': 'কেনাকাটার জন্য ধন্যবাদ',
};

const en = Object.fromEntries(Object.entries(bn).map(([english, bangla]) => [bangla, english]));
const productNamesBn: Record<string, string> = {
  Bananas: 'কলা', 'Ripe Bananas': 'পাকা কলা', 'Seasonal Mangoes': 'মৌসুমি আম', 'Ripe Mangoes': 'পাকা আম', Guava: 'পেয়ারা', 'Green Guava': 'কাঁচা পেয়ারা', Papaya: 'পেঁপে', Pineapple: 'আনারস', 'Green Coconut': 'ডাব', 'Sweet Limes': 'মিষ্টি লেবু',
  Potatoes: 'আলু', 'Red Onions': 'লাল পেঁয়াজ', Tomatoes: 'টমেটো', 'Fresh Tomatoes': 'তাজা টমেটো', 'Green Chillies': 'কাঁচা মরিচ', 'Eggplant (Begun)': 'বেগুন', Cauliflower: 'ফুলকপি', 'Spinach (Palong Shak)': 'পালং শাক', Cucumber: 'শসা', Carrots: 'গাজর',
  'Rohu Fish (Rui)': 'রুই মাছ', 'Rohu Fish': 'রুই মাছ', 'Hilsa Fish (Ilish)': 'ইলিশ মাছ', Tilapia: 'তেলাপিয়া মাছ', 'Fresh Chicken': 'তাজা মুরগি', Beef: 'গরুর মাংস', 'Farm Eggs': 'খামারের ডিম', 'Pasteurized Milk': 'পাস্তুরিত দুধ', 'Fresh Milk': 'তাজা দুধ', 'Plain Yogurt (Doi)': 'টক দই', 'Plain Yogurt': 'টক দই', Butter: 'মাখন',
  'White Bread': 'সাদা পাউরুটি', 'Frozen Paratha': 'হিমায়িত পরোটা', 'Miniket Rice': 'মিনিকেট চাল', 'Najirshail Rice': 'নাজিরশাইল চাল', 'Chinigura Aromatic Rice': 'চিনিগুঁড়া সুগন্ধি চাল', 'Atta (Whole Wheat Flour)': 'আটা', 'Muri (Puffed Rice)': 'মুড়ি', 'Masoor Dal (Red Lentils)': 'মসুর ডাল', 'Red Lentils (Masoor Dal)': 'মসুর ডাল', 'Mung Dal': 'মুগ ডাল', 'Chickpeas (Chola)': 'ছোলা',
  'Soybean Oil': 'সয়াবিন তেল', Sugar: 'চিনি', 'Iodized Salt': 'আয়োডিনযুক্ত লবণ', 'Turmeric Powder': 'হলুদ গুঁড়া', 'Red Chilli Powder': 'মরিচ গুঁড়া', 'Bangladeshi Tea': 'বাংলাদেশি চা', Chanachur: 'চানাচুর',
};
const banglaAll = { ...bn, ...productNamesBn };
const englishAll = { ...en, ...Object.fromEntries(Object.entries(productNamesBn).map(([english, bangla]) => [bangla, english])) };
export function localizeProductName(name: string, nameBn: string | undefined, language: Language) {
  if (language === 'en') return name;
  return nameBn?.trim() || productNamesBn[name] || name;
}
const originalText = new WeakMap<Text, { original: string; translated: string }>();
const originalAttributes = new WeakMap<Element, Map<string, { original: string; translated: string }>>();

function convert(value: string, language: Language) {
  const table = language === 'bn' ? banglaAll : englishAll;
  const trimmed = value.trim();
  if (!trimmed) return value;
  if (table[trimmed]) return value.replace(trimmed, table[trimmed]);
  let result = trimmed;
  for (const [from, to] of Object.entries(table).sort((a, b) => b[0].length - a[0].length)) {
    result = result.replaceAll(from, to);
  }
  return value.replace(trimmed, result);
}

export function translateDocument(root: ParentNode, language: Language) {
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
  let node: Node | null;
  while ((node = walker.nextNode())) {
    const text = node as Text;
    if (!text.nodeValue || text.parentElement?.closest('script,style,textarea,[data-no-translate]')) continue;
    let saved = originalText.get(text);
    if (!saved) { saved = { original: text.nodeValue, translated: text.nodeValue }; originalText.set(text, saved); }
    else if (text.nodeValue !== saved.translated) saved.original = text.nodeValue;
    const next = convert(saved.original, language);
    saved.translated = next;
    if (text.nodeValue !== next) text.nodeValue = next;
  }
  const elements = root instanceof Element ? [root, ...Array.from(root.querySelectorAll('*'))] : Array.from((root as Document).querySelectorAll?.('*') || []);
  for (const element of elements) {
    for (const attribute of ['placeholder', 'aria-label', 'title']) {
      const value = element.getAttribute(attribute);
      if (value === null) continue;
      let attributes = originalAttributes.get(element);
      if (!attributes) { attributes = new Map(); originalAttributes.set(element, attributes); }
      let saved = attributes.get(attribute);
      if (!saved) { saved = { original: value, translated: value }; attributes.set(attribute, saved); }
      else if (value !== saved.translated) saved.original = value;
      const next = convert(saved.original, language); saved.translated = next;
      if (value !== next) element.setAttribute(attribute, next);
    }
  }
}
