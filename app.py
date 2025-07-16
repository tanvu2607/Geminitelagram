# === SECTION 1: IMPORTS ===
import os
import logging
import asyncio
import threading
import time
from dotenv import load_dotenv
from PIL import Image
import io

# --- Third-party libraries ---
import google.generativeai as genai
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
import gradio as gr
import pandas as pd
import pandas_ta as ta
from pycoingecko import CoinGeckoAPI
from hyperliquid.info import Info
from hyperliquid.utils import constants

# === SECTION 2: CONFIGURATION & INITIALIZATION ===

# Load environment variables (for local testing)
load_dotenv()

# Get API keys from environment
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# Setup logging for debugging on servers
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.INFO
)
logger = logging.getLogger(__name__)

# --- Initialize API Clients ---
# Gemini
gemini_model = None
if not GEMINI_API_KEY:
    logger.error("!!! FATAL ERROR: GEMINI_API_KEY is not set!")
else:
    try:
        genai.configure(api_key=GEMINI_API_KEY)
        gemini_model = genai.GenerativeModel('gemini-1.5-flash')
        logger.info(">>> Gemini API configured successfully.")
    except Exception as e:
        logger.error(f"!!! FATAL ERROR configuring Gemini API: {e}")

# CoinGecko
cg = CoinGeckoAPI()
logger.info(">>> CoinGecko API client initialized.")

# Hyperliquid
hyper_info = Info(constants.MAINNET_API_URL, skip_ws=True)
logger.info(">>> Hyperliquid Info client initialized.")


# === SECTION 3: DATA FETCHING HELPER FUNCTIONS ===

async def get_coingecko_data(coin_id: str) -> dict | None:
    """Fetches macroeconomic data from CoinGecko."""
    try:
        logger.info(f"Fetching CoinGecko data for '{coin_id}'...")
        coin_data = cg.get_coin_by_id(
            id=coin_id, localization='false', tickers='false', market_data='true',
            community_data='false', developer_data='false', sparkline='false'
        )
        market_data = coin_data.get('market_data', {})
        return {
            "name": coin_data.get('name', 'N/A'),
            "symbol": coin_data.get('symbol', 'N/A').upper(),
            "price": f"${market_data.get('current_price', {}).get('usd', 0):,.2f}",
            "market_cap": f"${market_data.get('market_cap', {}).get('usd', 0):,.0f}",
            "volume_24h": f"${market_data.get('total_volume', {}).get('usd', 0):,.0f}",
            "ath": f"${market_data.get('ath', {}).get('usd', 0):,.2f}",
            "circulating_supply": f"{market_data.get('circulating_supply', 0):,.0f}",
            "total_supply": f"{market_data.get('total_supply', 0):,.0f}" if market_data.get('total_supply') else "Không giới hạn",
            "max_supply": f"{market_data.get('max_supply', 0):,.0f}" if market_data.get('max_supply') else "Không giới hạn",
        }
    except Exception as e:
        logger.error(f"Error fetching CoinGecko data for '{coin_id}': {e}")
        return None

async def get_hyperliquid_data(coin_symbol: str) -> dict | None:
    """Fetches derivatives and TA data from Hyperliquid."""
    try:
        logger.info(f"Fetching Hyperliquid data for '{coin_symbol}'...")
        meta = hyper_info.meta()
        universe = meta.get('universe', [])
        coin_info = next((item for item in universe if item["name"] == coin_symbol), None)

        if not coin_info:
            return {"error": f"Không tìm thấy coin {coin_symbol} trên Hyperliquid."}

        # Fetch candlestick data (100 recent 4-hour candles)
        end_time = int(time.time() * 1000)
        start_time = end_time - (100 * 4 * 60 * 60 * 1000)
        candles = hyper_info.candles_snapshot(coin=coin_symbol, interval="4h", startTime=start_time, endTime=end_time)

        if not candles:
             return {"error": f"Không có dữ liệu nến cho {coin_symbol} trên Hyperliquid."}

        df = pd.DataFrame(candles)
        df['t'] = pd.to_datetime(df['t'], unit='ms')
        for col in ['o', 'h', 'l', 'c', 'v']:
            df[col] = pd.to_numeric(df[col])

        # Calculate TA indicators
        rsi = df.ta.rsi(length=14).iloc[-1]
        
        return {
            "perpetual_price": f"${float(coin_info['markPx']):,.2f}",
            "open_interest": f"${float(coin_info['openInterest']):,.0f}",
            "funding_rate_1h": f"{float(coin_info['fundingRate']) * 100:.4f}%",
            "rsi_4h": f"{rsi:.2f}",
        }
    except Exception as e:
        logger.error(f"Error fetching Hyperliquid data for '{coin_symbol}': {e}")
        return None


# === SECTION 4: TELEGRAM COMMAND HANDLERS ===

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Sends a welcome message."""
    user = update.effective_user
    await update.message.reply_html(
        f"Xin chào <b>{user.full_name}</b>!\n\n"
        "Tôi là bot phân tích crypto sử dụng Gemini AI.\n"
        "Gõ /help để xem các lệnh."
    )

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Sends a help message."""
    await update.message.reply_html(
        "<b>Các lệnh có sẵn:</b>\n"
        "- Chat với tôi để trò chuyện.\n"
        "- Gửi ảnh/tài liệu để phân tích.\n"
        "- <code>/analyze [MÃ_COIN]</code> để phân tích chi tiết một đồng coin.\n"
        "<b>Ví dụ:</b> <code>/analyze BTC</code>"
    )

async def analyze_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Analyzes a crypto asset using data from multiple sources."""
    try:
        if not context.args:
            await update.message.reply_text("Cú pháp không đúng. Vui lòng nhập mã coin. Ví dụ: /analyze SOL")
            return
            
        coin_symbol = context.args[0].upper()
        # A simple map to convert common symbols to CoinGecko API IDs
        coin_id_map = {"BTC": "bitcoin", "ETH": "ethereum", "SOL": "solana", "BNB": "binancecoin", "XRP": "ripple", "DOGE": "dogecoin"}
        coin_id = coin_id_map.get(coin_symbol)

        if not coin_id:
            await update.message.reply_text(f"Xin lỗi, tôi chưa có dữ liệu cho mã '{coin_symbol}'. Vui lòng thử các mã phổ biến như BTC, ETH, SOL.")
            return

        thinking_message = await update.message.reply_text(f"⏳ Đang tổng hợp và phân tích dữ liệu cho {coin_symbol}, vui lòng chờ một lát...")

        gecko_data = await get_coingecko_data(coin_id)
        hyper_data = await get_hyperliquid_data(coin_symbol)

        if not gecko_data:
            await thinking_message.edit_text("Không thể lấy dữ liệu tổng quan từ CoinGecko. Vui lòng thử lại sau.")
            return

        # Build the prompt for Gemini
        prompt_parts = [
            f"Bạn là một nhà phân tích thị trường crypto chuyên nghiệp, khách quan và giàu kinh nghiệm. Hãy đưa ra một phân tích toàn diện về đồng {gecko_data['name']} ({coin_symbol}) dựa trên các dữ liệu sau.",
            "Sử dụng định dạng Markdown, in đậm các tiêu đề và dùng gạch đầu dòng cho các luận điểm.",
            "\n---",
            "**1. TỔNG QUAN THỊ TRƯỜNG (Dữ liệu từ CoinGecko):**",
            f"- Giá: {gecko_data['price']}",
            f"- Vốn hóa thị trường: {gecko_data['market_cap']}",
            f"- Khối lượng giao dịch 24h: {gecko_data['volume_24h']}",
            f"- Mức cao nhất mọi thời đại (ATH): {gecko_data['ath']}",
            "- **Tokenomics:**",
            f"  - Cung lưu thông: {gecko_data['circulating_supply']}",
            f"  - Cung tối đa: {gecko_data['max_supply']}"
        ]
        
        if hyper_data and "error" not in hyper_data:
            prompt_parts.extend([
                "\n**2. PHÂN TÍCH KỸ THUẬT & PHÁI SINH (Dữ liệu từ Hyperliquid, khung 4H):**",
                f"- Giá hợp đồng vĩnh cửu: {hyper_data.get('perpetual_price', 'N/A')}",
                f"- Open Interest (OI): {hyper_data.get('open_interest', 'N/A')} (Phản ánh tổng giá trị các vị thế đang mở)",
                f"- Funding Rate (1h): {hyper_data.get('funding_rate_1h', 'N/A')} (Dương = phe Long trả phí, Âm = phe Short trả phí)",
                f"- Chỉ số RSI(14): {hyper_data.get('rsi_4h', 'N/A')} (Trên 70 là quá mua, dưới 30 là quá bán)"
            ])
        else:
            prompt_parts.append("\n**2. PHÂN TÍCH PHÁI SINH:**\n- Không tìm thấy dữ liệu trên Hyperliquid.")

        prompt_parts.extend([
            "\n---\n",
            "**YÊU CẦU PHÂN TÍCH:**",
            "Dựa vào TẤT CẢ các dữ liệu trên, hãy đưa ra các nhận định sau:",
            "- **Tình hình chung:** Tóm tắt xu hướng hiện tại (tăng, giảm, đi ngang) và tâm lý thị trường.",
            "- **Tín hiệu Tích cực (Bullish):** Liệt kê các chỉ số đang cho thấy tín hiệu tốt.",
            "- **Tín hiệu Tiêu cực (Bearish):** Liệt kê các chỉ số đang cho thấy tín hiệu xấu hoặc cần cẩn trọng.",
            "- **Kết luận và Kịch bản:** Đưa ra một kết luận ngắn gọn và các vùng giá quan trọng (hỗ trợ/kháng cự) cần theo dõi.",
            "\n**TUYỆT ĐỐI KHÔNG ĐƯA RA LỜI KHUYÊN MUA/BÁN. Luôn kết thúc bằng câu sau:**",
            "\"***Lưu ý: Phân tích này được tạo bởi AI và chỉ mang tính chất tham khảo, không phải là lời khuyên đầu tư. Hãy tự nghiên cứu (DYOR) trước khi đưa ra bất kỳ quyết định nào.***\""
        ])
        
        final_prompt = "\n".join(prompt_parts)

        logger.info(f"Sending prompt for {coin_symbol} to Gemini for analysis...")
        response = gemini_model.generate_content(final_prompt)
        
        await thinking_message.edit_text(response.text, parse_mode='Markdown')

    except Exception as e:
        logger.error(f"Error in /analyze command: {e}")
        await update.message.reply_text(f"Đã có lỗi không xác định xảy ra: {e}")

async def handle_text_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handles regular text messages for general chat."""
    if not gemini_model:
        await update.message.reply_text("Lỗi: Gemini API chưa được cấu hình.")
        return
    await update.message.reply_text("...")
    response = gemini_model.generate_content(update.message.text)
    await update.message.reply_text(response.text)


# === SECTION 5: MAIN EXECUTION BLOCK ===

def main_bot_logic() -> None:
    """The main logic for the bot, runs in a separate thread."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    if not TELEGRAM_BOT_TOKEN:
        logger.error("!!! FATAL ERROR: TELEGRAM_BOT_TOKEN is not set!")
        return

    application = Application.builder().token(TELEGRAM_BOT_TOKEN).build()

    # Add handlers
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("analyze", analyze_command))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text_message))
    # You can add the media handler back if you want
    # application.add_handler(MessageHandler(filters.PHOTO | filters.Document.ALL, handle_media_message))

    logger.info(">>> Bot is starting polling...")
    application.run_polling(stop_signals=None)

if __name__ == "__main__":
    logger.info(">>> Initializing bot thread...")
    bot_thread = threading.Thread(target=main_bot_logic)
    bot_thread.start()

    logger.info(">>> Launching Gradio interface on the main thread...")
    iface = gr.Interface(
        fn=lambda: "Crypto Analysis Bot is running. Interact with it on Telegram.",
        inputs=None,
        outputs="text",
        title="Crypto Analysis Bot Status"
    )
    iface.launch()
