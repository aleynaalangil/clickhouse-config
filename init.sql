CREATE DATABASE IF NOT EXISTS hft_dashboard;

CREATE TABLE IF NOT EXISTS hft_dashboard.historical_trades
(
    symbol     String          CODEC(ZSTD(3)),
    side       Int8,
    price      Decimal64(8)    CODEC(ZSTD(3)),
    amount     Decimal64(8)    CODEC(ZSTD(3)),
    timestamp  DateTime64(6)   CODEC(DoubleDelta, ZSTD(1)),
    order_id   String          CODEC(ZSTD(3)),
    trader_id  UInt32          CODEC(ZSTD(1))
    )
    ENGINE = MergeTree()
    ORDER BY (symbol, timestamp)
    PARTITION BY toYYYYMM(timestamp)
    TTL toDateTime(timestamp) + INTERVAL 2 HOUR DELETE;

CREATE TABLE IF NOT EXISTS hft_dashboard.market_ohlc
(
    symbol      String        CODEC(ZSTD(3)),
    candle_time DateTime64(6) CODEC(DoubleDelta, ZSTD(1)),
    open        Decimal64(8)  CODEC(ZSTD(3)),
    high        Decimal64(8)  CODEC(ZSTD(3)),
    low         Decimal64(8)  CODEC(ZSTD(3)),
    close       Decimal64(8)  CODEC(ZSTD(3)),
    volume      Decimal64(8)  CODEC(ZSTD(3))
    )
    ENGINE = ReplacingMergeTree()
    ORDER BY (symbol, candle_time)
    PARTITION BY toYYYYMM(candle_time)
    TTL toDateTime(candle_time) + INTERVAL 90 DAY DELETE;

CREATE USER IF NOT EXISTS inserter_user
    IDENTIFIED WITH plaintext_password BY 'inserter_pass';

GRANT INSERT ON hft_dashboard.historical_trades TO inserter_user;
GRANT INSERT ON hft_dashboard.market_ohlc TO inserter_user;
GRANT INSERT ON hft_dashboard.market_ohlc TO inserter_user;
GRANT SELECT ON hft_dashboard.market_ohlc TO inserter_user;
GRANT SELECT ON hft_dashboard.historical_trades TO inserter_user;

GRANT SELECT ON hft_dashboard.* TO inserter_user;

-- ── exchange-sim tables ───────────────────────────────────────────────────────
CREATE USER IF NOT EXISTS exchange_user
    IDENTIFIED WITH plaintext_password BY 'exchange_pass';

CREATE DATABASE IF NOT EXISTS exchange;

CREATE TABLE IF NOT EXISTS exchange.users
(
    id            String          CODEC(ZSTD(3)),
    username      String          CODEC(ZSTD(3)),
    password_hash String          CODEC(ZSTD(3)),
    role          String,                          -- 'admin' | 'trader'
    balance_usdc  String          CODEC(ZSTD(3)), -- stored as decimal string
    created_at    DateTime64(6)   CODEC(DoubleDelta, ZSTD(1)), -- version col
    is_active     UInt8
)
ENGINE = ReplacingMergeTree(created_at)
ORDER BY id;

CREATE TABLE IF NOT EXISTS exchange.orders
(
    id            String          CODEC(ZSTD(3)),
    user_id       String          CODEC(ZSTD(3)),
    symbol        String          CODEC(ZSTD(3)),  -- 'SOL/USDC' | 'BTC/USDC'
    side          String,                           -- 'buy' | 'sell'
    price         String          CODEC(ZSTD(3)),
    amount        String          CODEC(ZSTD(3)),
    total_usdc    String          CODEC(ZSTD(3)),
    status        String,                           -- 'filled' | 'rejected'
    reject_reason String          CODEC(ZSTD(3)),  -- empty string when null
    created_at    DateTime64(6)   CODEC(DoubleDelta, ZSTD(1))
)
ENGINE = MergeTree()
ORDER BY (user_id, created_at)
PARTITION BY toYYYYMM(created_at);

CREATE TABLE IF NOT EXISTS exchange.positions
(
    user_id       String          CODEC(ZSTD(3)),
    symbol        String          CODEC(ZSTD(3)),
    quantity      String          CODEC(ZSTD(3)),  -- base asset held
    avg_buy_price String          CODEC(ZSTD(3)),  -- weighted average cost
    updated_at    DateTime64(6)   CODEC(DoubleDelta, ZSTD(1)) -- version col
)
ENGINE = ReplacingMergeTree(updated_at)
ORDER BY (user_id, symbol);

GRANT SELECT, INSERT ON exchange.* TO exchange_user;
GRANT SELECT ON hft_dashboard.* TO exchange_user;