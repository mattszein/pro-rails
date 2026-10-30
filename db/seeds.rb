# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
role_superadmin = Role.find_or_create_by!(name: "superadmin")
role_support = Role.find_or_create_by!(name: "support")

password_hash = RodauthApp.rodauth.allocate.password_hash("password")

# Core demo accounts
Account.find_or_create_by!(email: "matt@matt.com") do |account|
  account.role = role_superadmin
  account.password_hash = password_hash
  account.status = "verified"
end

Account.find_or_create_by!(email: "matinger@gmail.com") do |account|
  account.role = role_support
  account.password_hash = password_hash
  account.status = "verified"
end

Account.find_or_create_by!(email: "user@user.com") do |account|
  account.role = nil
  account.password_hash = password_hash
  account.status = "verified"
end

30.times do |i|
  Account.find_or_create_by!(email: "user#{i + 1}@user.com") do |account|
    account.role = nil
    account.password_hash = RodauthApp.rodauth.allocate.password_hash("password")
    account.status = "verified"
  end
end

# Create permissions and ensure roles are assigned idempotently
{
  application: [role_superadmin, role_support],
  account: [role_superadmin, role_support],
  ticket: [role_superadmin, role_support],
  role: [role_superadmin],
  announcement: [role_superadmin],
  permission: [role_superadmin],
  feature_flag: [role_superadmin],
  audience: [role_superadmin],
  article: [role_superadmin],
  support_ai: [role_superadmin]
}.each do |resource, roles|
  permission = Permission.find_or_create_by!(resource: resource) do |p|
    p.roles = roles
  end
  permission.roles = roles
end

# Default AI playbook: the fallback for tickets no other playbook matches. It
# must exist wherever the app runs; the assistant itself stays off globally
# until SupportAiConfig.enabled (SUPPORT_AI_ENABLED) is turned on.
Support::AiPlaybook.find_or_create_by!(is_default: true) do |playbook|
  playbook.name = "Default"
  playbook.enabled = true
  playbook.mode = :assist
  playbook.capabilities = Support::AiCapabilities.defaults.map { |c| c.key.to_s }
end

# Configure dashboard widgets per role/permission
superadmin_widgets = {
  ticket: ["tickets_analytics"],
  announcement: ["announcements_general"],
  account: ["accounts_general", "accounts_analytics"],
  role: ["roles_general"]
}

support_widgets = {
  ticket: ["tickets_personal", "tickets_general", "tickets_analytics"]
}

[role_superadmin, role_support].each do |role|
  widgets_for_role = (role == role_superadmin) ? superadmin_widgets : support_widgets

  widgets_for_role.each do |resource, widget_keys|
    permission = Permission.find_by!(resource: resource)
    PermissionRole.find_by!(permission_id: permission.id, role_id: role.id)
      .update!(dashboard_widget_keys: widget_keys)
  end
end

# Demo feature flag: gated by an audience scoped to the superadmin role, so
# the whole declare -> seed -> audience -> gate pipeline has one working example.
test_flag = FeatureFlag.find_or_create_by!(key: "test_feature_flag")
superadmin_audience = Audience.find_or_create_by!(name: "Superadmins") do |audience|
  audience.description = "Accounts holding the superadmin role."
  audience.audience_conditions.build(condition_key: "roles", value: [role_superadmin.id])
end
FeatureFlagAudience.find_or_create_by!(feature_flag: test_flag, audience: superadmin_audience)

# Demo data: 30 users, backdated tickets and announcements so dashboards have data
if Rails.env.development? || ENV["SEED_DEMO_DATA"] == "true"
  demo_users = 30.times.map do |i|
    created_at = rand(1..30).days.ago
    Account.find_or_create_by!(email: "demo#{i + 1}@example.com") do |account|
      account.role = nil
      account.password_hash = password_hash
      account.status = "verified"
      account.created_at = created_at
    end
  end

  support_agents = [Account.find_by(email: "matt@matt.com"), Account.find_by(email: "matinger@gmail.com")].compact
  superadmin_account = Account.find_by(email: "matt@matt.com")

  ticket_statuses = %i[open in_progress finished closed reopened reopen_requested]
  ticket_categories = %i[account_access technical_issue billing feature_request other]

  ticket_titles = [
    "Cannot log in to my account",
    "Password reset email not received",
    "Two-factor authentication broken",
    "Billing question about last invoice",
    "Refund request for duplicate charge",
    "Feature request: dark mode export",
    "Dashboard not loading on Safari",
    "Permission denied when uploading file",
    "Email notifications stopped arriving",
    "Subscription plan upgrade help",
    "Account deletion request",
    "Profile picture won't upload",
    "Slow performance on reports page",
    "Mobile app crash on startup",
    "Cannot invite team members",
    "Integration with third-party service fails",
    "Export to CSV missing rows",
    "Time zone displayed incorrectly",
    "API rate limit increase request",
    "Lost access after email change"
  ]

  if Support::Ticket.count < 40
    50.times do |i|
      creator = demo_users.sample
      status = ticket_statuses.sample
      created_at = rand(1..45).days.ago
      assignee = (status == :open) ? nil : support_agents.sample

      ticket = Support::Ticket.new(
        title: "#{ticket_titles.sample} (##{i + 1})",
        description: "Reported by #{creator.email}. This is sample seed data for the admin dashboard.",
        priority: rand(1..5),
        status: status,
        category: ticket_categories.sample,
        created: creator,
        assigned: assignee
      )
      ticket.save!
      resolution_delta = rand(2..72).hours
      ticket.update_columns(
        created_at: created_at,
        updated_at: %i[finished closed].include?(status) ? created_at + resolution_delta : created_at + rand(0..24).hours
      )
    end
  end

  if superadmin_account && Announcement.count < 8
    announcement_data = [
      {title: "Scheduled maintenance this Sunday", status: :published, days_ago: 25},
      {title: "New billing dashboard now live", status: :published, days_ago: 18},
      {title: "Two-factor authentication is now required", status: :published, days_ago: 10},
      {title: "Holiday support hours", status: :published, days_ago: 4},
      {title: "Upcoming API deprecation notice", status: :scheduled, days_ago: 2, scheduled_in: 3},
      {title: "Quarterly product review", status: :scheduled, days_ago: 1, scheduled_in: 7},
      {title: "Internal: dashboard redesign rollout", status: :draft, days_ago: 6},
      {title: "Draft: end-of-year recap", status: :draft, days_ago: 0}
    ]

    announcement_data.each_with_index do |data, index|
      created_at = data[:days_ago].days.ago
      announcement = Announcement.new(
        reference: "DEMO-#{Time.current.to_i}-#{index}",
        title: data[:title],
        body: "Body for #{data[:title]}. Seed data for the dashboard demo.",
        rich_body: "<p>Body for <strong>#{data[:title]}</strong>. Seed data for the dashboard demo.</p>",
        status: data[:status],
        author: superadmin_account,
        scheduled_at: data[:scheduled_in]&.days&.from_now,
        published_at: (data[:status] == :published) ? created_at : nil
      )
      announcement.save!
      announcement.update_columns(created_at: created_at, updated_at: created_at)
    end
  end

  # Help center articles (idempotent on locale + slug). Content describes the REAL app navigation
  # (labels come from config/locales); rows matched by (locale, slug) are refreshed so re-running
  # db:seed fixes demo content. Other articles are never touched.
  if superadmin_account
    article_data = {
      "en" => [
        [:account_access, "reset-your-password", "How to reset your password", "Forgot your password? Request a reset link in a few steps.", "<p>If you cannot log in, you can reset your password from the login page.</p><ol><li>Open the login page and choose the <strong>Forgot Password?</strong> link.</li><li>Enter your email and click <strong>Request Password</strong>.</li><li>Open the email we send you and follow the link. It expires after a limited time, so use it promptly.</li><li>Enter and confirm your new password, then click <strong>Reset Password</strong>.</li></ol><p>If you are already logged in and just want a new password, see \"Changing your password\".</p>"],
        [:account_access, "change-your-password", "Changing your password", "Change your password from Settings while you are logged in.", "<p>You can change your password at any time while you are logged in.</p><ol><li>In the left menu, choose <strong>Settings</strong>.</li><li>Open the <strong>Password</strong> section.</li><li>Enter your current password in <strong>Password</strong>, then your new password in <strong>New Password</strong> and again in <strong>Password Confirm</strong>.</li><li>Click <strong>Change Password</strong>.</li></ol><p>If you do not remember your current password, log out and use the <strong>Forgot Password?</strong> link on the login page instead.</p>"],
        [:account_access, "change-your-email", "Changing your account email", "How to update the email linked to your account.", "<p>The email address of your account cannot be changed from <strong>Settings</strong>. The Profile section only lets you edit your username, bio and photo.</p><p>To change it, open a ticket in the <strong>Account Access</strong> category (<strong>Support</strong> in the left menu, then <strong>Add ticket</strong>) with the new address, and a teammate will help you.</p>"],
        [:technical_issue, "dashboard-not-loading", "Dashboard not loading", "Steps to try when the dashboard stays blank or slow.", "<p>Refresh the page, clear your browser cache and try again in a private window. If the problem persists, open a ticket in the <strong>Technical Issue</strong> category and include your browser and version.</p>"],
        [:technical_issue, "file-upload-errors", "File upload errors", "Why an attachment may be rejected.", "<p>Ticket attachments accept PNG, JPEG, GIF, WebP and PDF files, up to 2 MB each and up to 10 files per ticket. Compress large files or convert them to a supported format and try again.</p>"],
        [:billing, "understanding-your-invoice", "Questions about a charge", "Where to ask about charges on your account.", "<p>This application does not show invoices or plans in your dashboard. If you have a question about a charge, open a ticket in the <strong>Billing</strong> category (<strong>Support</strong> in the left menu, then <strong>Add ticket</strong>) and describe what you see.</p>"],
        [:billing, "request-a-refund", "How to request a refund", "Duplicate or incorrect charge? Here is how to ask for a refund.", "<p>Open a ticket in the <strong>Billing</strong> category (<strong>Support</strong> in the left menu, then <strong>Add ticket</strong>) with the invoice number and a short description. A teammate will reply in the ticket conversation.</p>"],
        [:feature_request, "suggest-a-feature", "How to suggest a feature", "Tell us what you would like to see next.", "<p>Open a ticket in the <strong>Feature Request</strong> category (<strong>Support</strong> in the left menu, then <strong>Add ticket</strong>) describing the problem you want to solve. Concrete examples help us prioritize.</p>"],
        [:feature_request, "product-roadmap", "Product updates and announcements", "How new releases and changes are communicated.", "<p>There is no public roadmap. New releases and upcoming changes are published as announcements, which reach you as notifications: click the bell icon at the top right of the page, or choose <strong>View all notifications</strong> for the full list.</p>"],
        [:other, "contact-support", "Contacting support", "The best way to reach our team.", "<p>Choose <strong>Support</strong> in the left menu and click <strong>Add ticket</strong>. Pick a category, describe your question and optionally attach images or PDF files. You can follow the conversation in real time on the ticket page. If the assistant answers first, use <strong>Talk to a person</strong> to reach a teammate.</p>"],
        [:other, "support-hours", "How support requests are handled", "What happens after you open a ticket.", "<p>Support hours are not published in the app. You can open a ticket at any time: it waits for a teammate, and replies appear in the ticket conversation. When a ticket is marked as finished, you can ask to reopen it if you still need help.</p>"],
        [:general, "getting-started", "Getting started", "A short tour of the app menu.", "<p>Use the left menu to move around: <strong>Home</strong>, <strong>Settings</strong> (Profile, Appearance, Password and Remember), <strong>Support</strong> (your tickets) and <strong>Help</strong> (this help center). The bell icon at the top right shows your notifications.</p>"],
        [:general, "keyboard-and-accessibility", "Accessibility and appearance", "Themes, fonts and dark mode.", "<p>Go to <strong>Settings</strong> and open <strong>Appearance</strong> to choose a font and a theme. To switch between dark and light mode, use the dark/light toggle at the top of the page or <strong>Dark - Light</strong> in the left menu. The language switcher is also at the top of the page.</p>"]
      ],
      "es" => [
        [:account_access, "reset-your-password", "Cómo restablecer tu contraseña", "¿Olvidaste tu contraseña? Solicita un enlace en pocos pasos.", "<p>Si no puedes iniciar sesión, puedes restablecer tu contraseña desde la página de inicio de sesión.</p><ol><li>Abre la página de inicio de sesión y elige el enlace <strong>Forgot Password?</strong> (se muestra en inglés).</li><li>Ingresa tu correo electrónico y haz clic en <strong>Solicitar Contraseña</strong>.</li><li>Abre el correo que te enviamos y sigue el enlace. Expira después de un tiempo, así que úsalo pronto.</li><li>Ingresa y confirma tu nueva contraseña y haz clic en <strong>Restablecer Contraseña</strong>.</li></ol><p>Si ya iniciaste sesión y solo quieres una contraseña nueva, consulta \"Cambiar tu contraseña\".</p>"],
        [:account_access, "change-your-password", "Cambiar tu contraseña", "Cambia tu contraseña desde Configuración con tu sesión iniciada.", "<p>Puedes cambiar tu contraseña en cualquier momento con tu sesión iniciada.</p><ol><li>En el menú de la izquierda, elige <strong>Configuración</strong>.</li><li>Abre la sección <strong>Contraseña</strong>.</li><li>Ingresa tu contraseña actual en <strong>Contraseña</strong>, luego tu nueva contraseña en <strong>Nueva Contraseña</strong> y otra vez en <strong>Confirmar Contraseña</strong>.</li><li>Haz clic en <strong>Cambiar Contraseña</strong>.</li></ol><p>Si no recuerdas tu contraseña actual, cierra sesión y usa el enlace <strong>Forgot Password?</strong> (en inglés) de la página de inicio de sesión.</p>"],
        [:account_access, "change-your-email", "Cambiar el email de tu cuenta", "Cómo actualizar el email asociado a tu cuenta.", "<p>El correo electrónico de tu cuenta no se puede cambiar desde <strong>Configuración</strong>. La sección Perfil solo permite editar tu nombre de usuario, tu biografía y tu foto.</p><p>Para cambiarlo, abre un ticket en la categoría <strong>Acceso a Cuenta</strong> (<strong>Soporte</strong> en el menú de la izquierda y luego <strong>Agregar ticket</strong>) con la nueva dirección y un integrante del equipo te ayudará.</p>"],
        [:technical_issue, "dashboard-not-loading", "El panel no carga", "Qué probar si el panel queda en blanco o lento.", "<p>Actualiza la página, borra la caché del navegador e inténtalo en una ventana privada. Si persiste, abre un ticket en la categoría <strong>Problema Técnico</strong> indicando tu navegador y su versión.</p>"],
        [:technical_issue, "file-upload-errors", "Errores al subir archivos", "Por qué un adjunto puede ser rechazado.", "<p>Los adjuntos de los tickets admiten archivos PNG, JPEG, GIF, WebP y PDF, de hasta 2 MB cada uno y hasta 10 archivos por ticket. Comprime los archivos grandes o conviértelos a un formato admitido e inténtalo de nuevo.</p>"],
        [:billing, "understanding-your-invoice", "Consultas sobre un cargo", "Dónde preguntar por cargos de tu cuenta.", "<p>Esta aplicación no muestra facturas ni planes en tu panel. Si tienes una consulta sobre un cargo, abre un ticket en la categoría <strong>Facturación</strong> (<strong>Soporte</strong> en el menú de la izquierda y luego <strong>Agregar ticket</strong>) y describe lo que ves.</p>"],
        [:billing, "request-a-refund", "Cómo solicitar un reembolso", "¿Cargo duplicado o incorrecto? Así puedes pedir un reembolso.", "<p>Abre un ticket en la categoría <strong>Facturación</strong> (<strong>Soporte</strong> en el menú de la izquierda y luego <strong>Agregar ticket</strong>) con el número de factura y una breve descripción. Un integrante del equipo responderá en la conversación del ticket.</p>"],
        [:feature_request, "suggest-a-feature", "Cómo sugerir una función", "Cuéntanos qué te gustaría ver próximamente.", "<p>Abre un ticket en la categoría <strong>Solicitud de Función</strong> (<strong>Soporte</strong> en el menú de la izquierda y luego <strong>Agregar ticket</strong>) describiendo el problema que quieres resolver. Los ejemplos concretos nos ayudan a priorizar.</p>"],
        [:feature_request, "product-roadmap", "Novedades y anuncios del producto", "Cómo comunicamos nuevas versiones y cambios.", "<p>No hay una hoja de ruta pública. Las nuevas versiones y los cambios próximos se publican como anuncios, que te llegan como notificaciones: haz clic en la campana de la parte superior derecha o elige <strong>Ver todas las notificaciones</strong> para ver la lista completa.</p>"],
        [:other, "contact-support", "Contactar a soporte", "La mejor forma de comunicarte con el equipo.", "<p>Elige <strong>Soporte</strong> en el menú de la izquierda y haz clic en <strong>Agregar ticket</strong>. Elige una categoría, describe tu consulta y, si quieres, adjunta imágenes o archivos PDF. Puedes seguir la conversación en tiempo real en la página del ticket. Si primero responde el asistente, usa <strong>Hablar con una persona</strong> para comunicarte con el equipo.</p>"],
        [:other, "support-hours", "Cómo se atienden las solicitudes", "Qué pasa después de abrir un ticket.", "<p>El horario de soporte no se publica en la aplicación. Puedes abrir un ticket en cualquier momento: queda a la espera de un integrante del equipo y las respuestas aparecen en la conversación del ticket. Cuando un ticket se marca como finalizado, puedes pedir reabrirlo si aún necesitas ayuda.</p>"],
        [:general, "getting-started", "Primeros pasos", "Un breve recorrido por el menú de la aplicación.", "<p>Usa el menú de la izquierda para moverte: <strong>Inicio</strong>, <strong>Configuración</strong> (Perfil, Apariencia, Contraseña y Recordar), <strong>Soporte</strong> (tus tickets) y <strong>Ayuda</strong> (este centro de ayuda). La campana de la parte superior derecha muestra tus notificaciones.</p>"],
        [:general, "keyboard-and-accessibility", "Accesibilidad y apariencia", "Temas, fuentes y modo oscuro.", "<p>Ve a <strong>Configuración</strong> y abre <strong>Apariencia</strong> para elegir una fuente y un tema. Para alternar entre modo oscuro y claro, usa el interruptor de la parte superior de la página u <strong>Oscuro - Claro</strong> en el menú de la izquierda. El selector de idioma también está en la parte superior de la página.</p>"]
      ]
    }

    article_data.each do |locale, rows|
      rows.each do |category, slug, title, summary, body|
        article = Support::Article.find_or_initialize_by(locale: locale, slug: slug)
        if article.new_record?
          article.assign_attributes(category: category, title: title, summary: summary, body: body, status: :published,
            published_at: rand(1..30).days.ago, author: superadmin_account)
          article.save!
        elsif article.title != title || article.summary != summary || article.category.to_sym != category ||
            article.body.to_plain_text != ActionText::Content.new(body).to_plain_text
          article.update!(category: category, title: title, summary: summary, body: body)
        end
      end
    end

    Support::Article.find_or_create_by!(locale: "en", slug: "draft-two-factor-guide") do |article|
      article.category = :account_access
      article.title = "Setting up two-factor authentication"
      article.summary = "Draft: how to enable two-factor authentication."
      article.body = "<p>Work in progress.</p>"
      article.status = :draft
      article.author = superadmin_account
    end
  end

  # Example triage-only playbook (idempotent on name)
  Support::AiPlaybook.find_or_create_by!(name: "Billing (triage only)") do |playbook|
    playbook.category_keys = ["billing"]
    playbook.mode = :triage_only
    playbook.capabilities = %w[account_facts past_tickets similar_tickets investigate_note auto_set_priority]
  end

  # Demo AI conversations in different ai_states, no LLM needed (idempotent on title).
  ai_demo_requester = demo_users.first
  ai_demo_transcript = lambda do |title|
    [
      {role: "system", content: "You are the support assistant. Search the knowledge base before answering."},
      {role: "user", content: "Ticket: #{title}"},
      {role: "assistant", content: "", tool_calls: [{id: "call_demo_1", name: "search_articles", arguments: {query: "contact support"}}]},
      {role: "tool", content: "[{\"id\":1,\"title\":\"Contacting support\"}]", tool_call_id: "call_demo_1"},
      {role: "assistant", content: "You can open a ticket from your dashboard at any time."}
    ].map(&:deep_stringify_keys)
  end

  ai_demo_article_ids = Support::Article.where(locale: "en", slug: %w[dashboard-not-loading contact-support]).pluck(:id)
  ai_demo_default_playbook = Support::AiPlaybook.find_by(is_default: true)

  [
    {
      title: "Demo AI: dashboard stays blank",
      ai_state: :awaiting_user,
      status: :open,
      messages: [
        [:human, "My dashboard stays blank after login."],
        [:ai, "Thanks for reaching out. Try refreshing and clearing your cache; these articles walk you through it. Did that solve it?", {article_ids: ai_demo_article_ids, resolution_proposed: true}]
      ]
    },
    {
      title: "Demo AI: refund for a duplicate charge",
      ai_state: :handoff_requested,
      status: :open,
      messages: [
        [:human, "I was charged twice this month."],
        [:ai, "We're looking into this. I've passed your request to a teammate on our support team, and they'll follow up here.", {article_ids: [], resolution_proposed: false}]
      ],
      notes: [[:ai, "User reports being charged twice this month.\nHelp center: no article answered this."], [:system, "The assistant requested a human: billing issue needs an agent."]]
    },
    {
      title: "Demo AI: how do I contact support",
      ai_state: :resolved,
      status: :finished,
      messages: [
        [:human, "How can I contact the team?"],
        [:ai, "You can open a ticket from your dashboard at any time.", {article_ids: ai_demo_article_ids.last(1), resolution_proposed: true}],
        [:human, "Perfect, that solved it."]
      ]
    }
  ].each do |demo|
    existing = Support::Ticket.find_by(title: demo[:title])
    if existing
      existing.ai_runs.where("transcript = '[]'::jsonb").update_all(transcript: ai_demo_transcript.call(demo[:title]))
      next
    end

    ticket = Support::Ticket.create!(
      title: demo[:title], description: demo[:messages].first[1], category: :other,
      created: ai_demo_requester, status: demo[:status], ai_state: demo[:ai_state]
    )
    demo[:messages].each do |sender, content, metadata|
      ticket.conversation.messages.create!(
        sender: sender, account: (ai_demo_requester if sender == :human), content: content, metadata: metadata || {}
      )
    end
    demo.fetch(:notes, []).each do |kind, body|
      ticket.notes.create!(kind: kind, account: nil, body: body)
    end
    ticket.ai_runs.create!(run_trigger: :ticket_created, step: :handle, status: :succeeded, model: "demo-model",
      input_tokens: 812, output_tokens: 164, latency_ms: 1380, tool_calls: [{name: "search_articles", arguments: {}}],
      transcript: ai_demo_transcript.call(demo[:title]),
      playbook: ai_demo_default_playbook, playbook_snapshot: ai_demo_default_playbook&.snapshot || {})
  end
end
