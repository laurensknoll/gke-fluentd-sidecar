import logging
import logging.config
import os

log_folder = os.getenv("LOG_FOLDER", ".")
logging.basicConfig(filename=os.path.join(log_folder, 'debug.log'),
                    filemode='a',
                    format='[%(asctime)s] %(name)s: %(levelname)s %(message)s',
                    level=logging.DEBUG)

logger = logging.getLogger('gunicorn')

def app(environ, start_response):
    logger.info("Got request..")

    data = b"Hello, World!\n"
    start_response("200 OK", [
        ("Content-Type", "text/plain"),
        ("Content-Length", str(len(data)))
    ])
    return iter([data])