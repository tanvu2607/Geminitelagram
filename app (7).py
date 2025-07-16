import os
import logging
import asyncio
import threading
from dotenv import load_dotenv
from PIL import Image
import io

# === Thư viện bắt buộc ===
import google.generativeai as genai
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
import gradio as gr

# --- 1. CẤU HÌNH BAN ĐẦU ---

load_dotenv()
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.INFO
)
logger = logging.getLogger(__name__)

gemini_model = None
if not GEMINI_API_KEY:
    logger.error("!!! LỖI NGHIÊM TRỌNG: GEMINI_API_KEY chưa được thiết lập trong Secrets!")
else:
    try:
        genai.configure(api_key=GEMINI_API_KEY)
        gemini_model = genai.GenerativeModel('gemini-1.5-flash')
        logger.info(">>> Đã cấu hình thành công Gemini API.")
    except Exception as e:
        logger.error(f"!!! LỖI NGHIÊM TRỌNG khi cấu hình Gemini API: {e}")

# --- 2. CÁC HÀM XỬ LÝ LỆNH CỦA TELEGRAM BOT ---

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user = update.effective_user
    logger.info(f"Người dùng {user.full_name} đã bắt đầu cuộc trò chuyện.")
    welcome_message = (
        f"Xin chào <b>{user.full_name}</b>!\n\n"
        "Tôi là bot được trang bị <b>Gemini 1.5 Flash</b>, chạy trên Hugging Face Spaces.\n\n"
        "Hãy thử các chức năng sau:\n"
        "1. Chat với tôi bằng văn bản.\n"
        "2. Gửi một bức ảnh và đặt câu hỏi về nó (ví dụ: 'mô tả ảnh này').\n"
        "3. Gửi một file tài liệu (TXT, PDF,...) và yêu cầu tóm tắt.\n\n"
        "<i>Lưu ý: Với ảnh và tài liệu, hãy gửi kèm theo yêu cầu của bạn trong phần caption nhé!</i>"
    )
    await update.message.reply_html(welcome_message)

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    logger.info(f"Người dùng {update.effective_user.full_name} đã yêu cầu trợ giúp.")
    help_message = (
        "<b>Hướng dẫn sử dụng:</b>\n"
        "- <b>Chat thông thường:</b> Gửi bất kỳ tin nhắn văn bản nào để trò chuyện.\n"
        "- <b>Phân tích ảnh:</b> Gửi ảnh kèm theo một câu lệnh trong caption (ví dụ: 'Đây là con vật gì?').\n"
        "- <b>Hỏi đáp tài liệu:</b> Gửi file (.txt, .md, .pdf...) kèm caption để yêu cầu tóm tắt hoặc hỏi đáp.\n"
        "\nBot đang sử dụng mô hình Gemini 1.5 Flash."
    )
    await update.message.reply_html(help_message)

async def handle_text_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if not gemini_model:
        await update.message.reply_text("Lỗi: Gemini API chưa được cấu hình. Vui lòng kiểm tra lại API Key.")
        return
    user_text = update.message.text
    chat_id = update.effective_chat.id
    logger.info(f"Nhận tin nhắn văn bản từ chat ID {chat_id}: '{user_text}'")
    thinking_message = await context.bot.send_message(chat_id=chat_id, text="Gemini đang suy nghĩ...")
    try:
        response = gemini_model.generate_content(user_text)
        await context.bot.edit_message_text(text=response.text, chat_id=chat_id, message_id=thinking_message.message_id)
        logger.info(f"Đã gửi phản hồi Gemini cho chat ID {chat_id}.")
    except Exception as e:
        logger.error(f"Lỗi khi gọi Gemini API cho tin nhắn văn bản: {e}")
        await context.bot.edit_message_text(text=f"Rất tiếc, đã có lỗi xảy ra: {e}", chat_id=chat_id, message_id=thinking_message.message_id)

async def handle_media_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if not gemini_model:
        await update.message.reply_text("Lỗi: Gemini API chưa được cấu hình.")
        return
    prompt = update.message.caption or "Hãy phân tích và mô tả nội dung này một cách chi tiết."
    chat_id = update.effective_chat.id
    logger.info(f"Nhận file media từ chat ID {chat_id} với prompt: '{prompt}'")
    thinking_message = await context.bot.send_message(chat_id=chat_id, text="Gemini đang phân tích file...")
    try:
        content_parts = [prompt]
        if update.message.photo:
            file_id = update.message.photo[-1].file_id
            new_file = await context.bot.get_file(file_id)
            with io.BytesIO() as mem_file:
                await new_file.download_to_memory(mem_file)
                mem_file.seek(0)
                img = Image.open(mem_file)
                content_parts.append(img)
        elif update.message.document:
            file_id = update.message.document.file_id
            new_file = await context.bot.get_file(file_id)
            with io.BytesIO() as mem_file:
                await new_file.download_to_memory(mem_file)
                mem_file.seek(0)
                file_name = update.message.document.file_name or "uploaded_file"
                logger.info(f"Đang tải lên Google file: {file_name}")
                uploaded_file = genai.upload_file(path=mem_file, display_name=file_name)
                content_parts.append(uploaded_file)
        else:
            await context.bot.edit_message_text(text="Loại file này chưa được hỗ trợ.", chat_id=chat_id, message_id=thinking_message.message_id)
            return
        response = gemini_model.generate_content(content_parts)
        await context.bot.edit_message_text(text=response.text, chat_id=chat_id, message_id=thinking_message.message_id)
        logger.info(f"Đã gửi phản hồi Gemini cho file media từ chat ID {chat_id}.")
    except Exception as e:
        logger.error(f"Lỗi khi xử lý media: {e}")
        await context.bot.edit_message_text(text=f"Rất tiếc, đã có lỗi xảy ra khi xử lý file: {e}", chat_id=chat_id, message_id=thinking_message.message_id)

# --- 3. HÀM CHÍNH ĐỂ KHỞI CHẠY BOT ---

def main_bot_logic() -> None:
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    if not TELEGRAM_BOT_TOKEN:
        logger.error("!!! LỖI NGHIÊM TRỌNG: TELEGRAM_BOT_TOKEN chưa được thiết lập!")
        return
    application = Application.builder().token(TELEGRAM_BOT_TOKEN).build()
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text_message))
    application.add_handler(MessageHandler(filters.PHOTO | filters.Document.ALL, handle_media_message))
    logger.info(">>> Bot đang khởi động polling...")
    
    # SỬA LỖI: Thêm stop_signals=None để tránh lỗi "set_wakeup_fd" trong luồng phụ
    application.run_polling(stop_signals=None)

# --- 4. GIAO DIỆN GRADIO VÀ KHỞI CHẠY LUỒNG ---

if __name__ == "__main__":
    logger.info(">>> Khởi tạo luồng cho bot...")
    bot_thread = threading.Thread(target=main_bot_logic)
    bot_thread.start()

    logger.info(">>> Khởi chạy giao diện Gradio trên luồng chính...")
    iface = gr.Interface(
        fn=lambda: "Telegram Bot đang chạy ngầm. Hãy tương tác với bot của bạn trên ứng dụng Telegram.",
        inputs=None,
        outputs="text",
        title="Trạng thái Gemini Telegram Bot",
        description="Bot đang chạy. Mọi tương tác diễn ra trên Telegram."
    )
    iface.launch()