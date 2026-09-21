require 'prawn'

class Conversations::PdfExportService
  # The built-in AFM fonts only cover Windows-1252, which is enough for
  # portuguese and the latin alphabet. Anything outside it (emoji, CJK) is
  # dropped so the export never blows up on an unexpected character.
  ENCODING_OPTIONS = { invalid: :replace, undef: :replace, replace: '' }.freeze

  def initialize(conversation:, timezone: nil)
    @conversation = conversation
    @timezone = Time.find_zone(timezone) || Time.zone
  end

  def perform
    Prawn::Fonts::AFM.hide_m17n_warning = true
    pdf = Prawn::Document.new(page_size: 'A4', margin: 40, info: document_info)
    pdf.font 'Helvetica'

    draw_header(pdf)
    draw_messages(pdf)
    draw_page_numbers(pdf)

    pdf.render
  end

  def filename
    "conversa-#{@conversation.display_id}.pdf"
  end

  private

  def document_info
    { Title: "Conversa ##{@conversation.display_id}", Creator: 'Chatwoot', CreationDate: Time.current }
  end

  def sanitize(text)
    text.to_s.encode('Windows-1252', **ENCODING_OPTIONS).encode('UTF-8')
  end

  def format_time(time)
    time.in_time_zone(@timezone).strftime('%d/%m/%Y %H:%M')
  end

  def draw_header(pdf)
    pdf.text "Conversa ##{@conversation.display_id}", size: 18, style: :bold
    pdf.move_down 8

    header_lines.each do |label, value|
      pdf.text "<b>#{label}:</b> #{sanitize(value)}", size: 9, inline_format: true, color: '444444'
    end

    pdf.move_down 6
    pdf.stroke_color 'cccccc'
    pdf.stroke_horizontal_rule
    pdf.move_down 16
  end

  def header_lines
    lines = {
      'Contato' => @conversation.contact&.name,
      'Caixa de entrada' => @conversation.inbox&.name,
      'Responsável' => @conversation.assignee&.available_name || 'Não atribuída',
      'Status' => @conversation.status,
      'Criada em' => format_time(@conversation.created_at)
    }
    labels = @conversation.label_list
    lines['Etiquetas'] = labels.join(', ') if labels.any?
    lines['Exportada em'] = format_time(Time.current)
    lines
  end

  def messages
    @conversation.messages.includes(:sender, :attachments).order(created_at: :asc)
  end

  def draw_messages(pdf)
    messages.each do |message|
      message.activity? ? draw_activity(pdf, message) : draw_message(pdf, message)
    end
  end

  def draw_activity(pdf, message)
    pdf.text "#{format_time(message.created_at)} — #{sanitize(message.content)}",
             size: 8, style: :italic, color: '888888', align: :center
    pdf.move_down 10
  end

  def draw_message(pdf, message)
    pdf.text "#{sanitize(sender_name(message))}#{private_tag(message)}  ·  #{format_time(message.created_at)}",
             size: 9, style: :bold, color: message.private? ? 'b38600' : '333333'
    pdf.move_down 2
    pdf.text sanitize(message.content), size: 10 if message.content.present?
    draw_attachments(pdf, message)
    pdf.move_down 12
  end

  def sender_name(message)
    message.sender&.try(:available_name) || message.sender&.name || (message.incoming? ? 'Contato' : 'Sistema')
  end

  def private_tag(message)
    message.private? ? '  [nota privada]' : ''
  end

  def draw_attachments(pdf, message)
    return if message.attachments.blank?

    pdf.move_down 4
    message.attachments.each do |attachment|
      name = sanitize(attachment.file.filename.to_s.presence || attachment.file_type)
      pdf.text "Anexo: <link href='#{attachment.file_url}'>#{name}</link>",
               size: 9, inline_format: true, color: '1f73b7'
    end
  end

  def draw_page_numbers(pdf)
    pdf.number_pages '<page>/<total>', at: [pdf.bounds.right - 50, -20], size: 8, color: '888888'
  end
end
