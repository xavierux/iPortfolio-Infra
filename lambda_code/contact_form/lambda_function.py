# lambda_function.py
import json
import boto3
import os
import logging

# Configurar logging básico
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Obtener variables de entorno
RECIPIENT_EMAIL = os.environ.get('RECIPIENT_EMAIL')
SOURCE_EMAIL = os.environ.get('SOURCE_EMAIL')
SES_REGION = os.environ.get('SES_REGION', 'us-east-1') # Default si no está seteada

# Instanciar cliente SES
ses = boto3.client('ses', region_name=SES_REGION)

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    # CORS Headers - Importante para que el navegador permita la llamada desde tu sitio
    headers = {
        "Access-Control-Allow-Origin": "*", # Sé más específico en producción
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "OPTIONS,POST"
    }

    # Manejar preflight OPTIONS request para CORS
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
         logger.info("Handling OPTIONS request")
         return {
             'statusCode': 200,
             'headers': headers,
             'body': json.dumps('Handled OPTIONS request')
         }

    # Validar que las variables de entorno necesarias están presentes
    if not RECIPIENT_EMAIL or not SOURCE_EMAIL:
        logger.error("Configuration error: Missing recipient or source email environment variables.")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': 'Internal server configuration error.'})
        }

    try:
        # El cuerpo de la petición viene como string, hay que parsearlo
        if 'body' not in event:
             raise ValueError("Missing 'body' in event")

        body_str = event['body']
        if not body_str:
             raise ValueError("Empty body received")

        logger.info(f"Request body string: {body_str}")
        form_data = json.loads(body_str)
        logger.info(f"Parsed form data: {form_data}")

        # Extraer datos (con validación básica)
        name = form_data.get('name', '').strip()
        email = form_data.get('email', '').strip()
        subject = form_data.get('subject', '').strip()
        message = form_data.get('message', '').strip()

        if not all([name, email, subject, message]):
            logger.warning("Validation error: Missing required fields.")
            return {
                'statusCode': 400, # Bad Request
                'headers': headers,
                'body': json.dumps({'message': 'Missing required fields.'})
            }

        # Construir el cuerpo del email
        email_body = f"""
        Mensaje recibido desde el formulario de contacto del portafolio:

        Nombre: {name}
        Email: {email}
        Asunto: {subject}

        Mensaje:
        {message}
        """

        # Enviar email usando SES
        logger.info(f"Attempting to send email via SES from {SOURCE_EMAIL} to {RECIPIENT_EMAIL}")
        response = ses.send_email(
            Source=SOURCE_EMAIL,
            Destination={
                'ToAddresses': [RECIPIENT_EMAIL]
            },
            Message={
                'Subject': {
                    'Data': f"Nuevo Mensaje del Portafolio: {subject}",
                    'Charset': 'UTF-8'
                },
                'Body': {
                    'Text': {
                        'Data': email_body,
                        'Charset': 'UTF-8'
                    }
                    # Puedes añadir 'Html' si quieres un email más elaborado
                    # 'Html': {
                    #     'Data': email_body_html,
                    #     'Charset': 'UTF-8'
                    # }
                }
            }
            # ReplyToAddresses=[email] # Opcional: poner el email del remitente en Reply-To
        )
        logger.info(f"SES send_email response: {response}")

        # Devolver respuesta de éxito
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'message': 'Message sent successfully!'})
        }

    except json.JSONDecodeError as e:
         logger.error(f"JSON Decode Error: {e}")
         return {
             'statusCode': 400, # Bad Request
             'headers': headers,
             'body': json.dumps({'message': 'Invalid request body format.'})
         }
    except ValueError as e:
         logger.error(f"Value Error: {e}")
         return {
             'statusCode': 400, # Bad Request
             'headers': headers,
             'body': json.dumps({'message': str(e)})
         }
    except ses.exceptions.MessageRejected as e:
         logger.error(f"SES Message Rejected: {e} - Check SES identity verification and permissions.")
         return {
             'statusCode': 500,
             'headers': headers,
             'body': json.dumps({'message': f"Could not send email: {e}"})
         }
    except Exception as e:
        # Capturar cualquier otro error inesperado
        logger.error(f"Unexpected error: {e}", exc_info=True)
        return {
            'statusCode': 500, # Internal Server Error
            'headers': headers,
            'body': json.dumps({'message': 'An unexpected error occurred.'})
        }