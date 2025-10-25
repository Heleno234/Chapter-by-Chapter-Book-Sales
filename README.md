# 📚 Chapter-by-Chapter Book Sales

A Stacks blockchain smart contract enabling authors to sell books chapter by chapter with built-in anti-plagiarism protection.

## 🌟 Features

- 📖 **Chapter-by-Chapter Sales**: Authors can publish and sell individual chapters
- 🔒 **Anti-Plagiarism Protection**: Content hash verification prevents duplicate content
- 💰 **Instant Payments**: Direct STX payments with automatic royalty distribution
- 📊 **Analytics**: Track sales, earnings, and reader engagement
- 🏪 **Digital Library**: Readers build personal chapter collections
- ⚡ **Platform Fee**: Configurable platform commission system

## 🚀 Quick Start

### For Authors

1. **Create a Book**
```clarity
(contract-call? .chapter-by-book create-book 
  "My Amazing Book" 
  "A thrilling adventure story" 
  "https://example.com/cover.jpg" 
  u1000000) ;; 1 STX per chapter
```

2. **Publish Chapters**
```clarity
(contract-call? .chapter-by-book publish-chapter 
  u1                              ;; book-id
  u1                              ;; chapter-number
  "The Beginning"                 ;; chapter-title
  0x1234567890abcdef...          ;; content-hash
  "Our hero begins their journey..." ;; preview
  u2500)                         ;; word-count
```

### For Readers

1. **Purchase a Chapter**
```clarity
(contract-call? .chapter-by-book purchase-chapter u1 u1)
```

2. **Check Your Library**
```clarity
(contract-call? .chapter-by-book get-user-library tx-sender u1)
```

## 📋 Contract Functions

### 📝 Author Functions

| Function | Description |
|----------|-------------|
| `create-book` | Register a new book with title, description, and pricing |
| `publish-chapter` | Add a new chapter with anti-plagiarism verification |
| `deactivate-book` | Temporarily disable book sales |
| `reactivate-book` | Re-enable book sales |

### 🛒 Reader Functions

| Function | Description |
|----------|-------------|
| `purchase-chapter` | Buy access to a specific chapter |

### 🔍 Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-book` | Retrieve book information |
| `get-chapter` | Get chapter details and preview |
| `has-purchased-chapter` | Check if user owns a chapter |
| `get-book-earnings` | View book sales statistics |
| `get-author-stats` | Author performance metrics |
| `check-plagiarism` | Verify content originality |
| `get-user-library` | Reader's purchased chapters |

## 🔧 Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/chapter-by-chapter-book-sales.git
cd chapter-by-chapter-book-sales
```

2. **Install dependencies**
```bash
npm install
```

3. **Deploy with Clarinet**
```bash
clarinet deploy --testnet
```

## 💡 Usage Examples

### Complete Author Workflow

```clarity
;; 1. Create your book
(contract-call? .chapter-by-book create-book 
  "Space Adventures" 
  "Epic sci-fi journey across galaxies" 
  "https://mysite.com/space-cover.jpg" 
  u500000)

;; 2. Publish Chapter 1
(contract-call? .chapter-by-book publish-chapter 
  u1 u1 "Launch Day" 
  0xabcd1234... 
  "The countdown begins..." 
  u3200)

;; 3. Publish Chapter 2
(contract-call? .chapter-by-book publish-chapter 
  u1 u2 "Into the Void" 
  0xefgh5678... 
  "Stars fade into darkness..." 
  u2800)
```

### Reader Experience

```clarity
;; Check book details
(contract-call? .chapter-by-book get-book u1)

;; Buy Chapter 1
(contract-call? .chapter-by-book purchase-chapter u1 u1)

;; Buy Chapter 2
(contract-call? .chapter-by-book purchase-chapter u1 u2)

;; View your collection
(contract-call? .chapter-by-book get-user-library tx-sender u1)
```

## 🛡️ Anti-Plagiarism System

The contract uses SHA-256 content hashes to ensure:
- ✅ No duplicate content across the platform
- ✅ Original content verification
- ✅ Immutable proof of publication timestamp
- ✅ Author authenticity protection

## 💎 Economics

- **Platform Fee**: Default 2.5% (configurable by admin)
- **Author Earnings**: 97.5% of each sale
- **Instant Payments**: No escrow delays
- **Transparent Tracking**: All transactions on-chain

## 🧪 Testing

```bash
npm test
```

## 📄 License

MIT License - build amazing things! 🚀

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

- 📧 Email: support@chapterbychapter.com
- 💬 Discord: [Join our community](https://discord.gg/chapterbychapter)
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/chapter-by-chapter-book-sales/issues)

---

Made with ❤️ for the creator economy on Stacks blockchain
