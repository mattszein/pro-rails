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
  article: [role_superadmin]
}.each do |resource, roles|
  permission = Permission.find_or_create_by!(resource: resource) do |p|
    p.roles = roles
  end
  permission.roles = roles
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

  # Help center articles (idempotent on locale + slug)
  if superadmin_account
    article_data = {
      "en" => [
        [:account_access, "reset-your-password", "How to reset your password", "Forgot your password? Request a reset link in a few steps.", "Open the login page and choose <strong>Forgot your password</strong>. Enter your email and we will send you a link. The link expires after a short time, so use it promptly."],
        [:account_access, "change-your-email", "Changing your account email", "Update the email address linked to your account.", "Go to Settings and edit your email. You will need to confirm the new address before it becomes active."],
        [:technical_issue, "dashboard-not-loading", "Dashboard not loading", "Steps to try when the dashboard stays blank or slow.", "Refresh the page, clear your browser cache and try again in a private window. If the problem persists, open a ticket and include your browser version."],
        [:technical_issue, "file-upload-errors", "File upload errors", "Why an attachment may be rejected.", "Attachments have limits on count, size and file type. Compress large files or convert them to a supported format and try again."],
        [:billing, "understanding-your-invoice", "Understanding your invoice", "A quick guide to the items on your invoice.", "Each invoice lists the plan, any add-ons and applicable taxes. Contact support if you see a charge you do not recognize."],
        [:billing, "request-a-refund", "How to request a refund", "Duplicate or incorrect charge? Here is how to ask for a refund.", "Open a ticket in the Billing category with the invoice number and a short description. We review refund requests as quickly as possible."],
        [:feature_request, "suggest-a-feature", "How to suggest a feature", "Tell us what you would like to see next.", "Create a ticket in the Feature Request category describing the problem you want to solve. Concrete examples help us prioritize."],
        [:feature_request, "product-roadmap", "Where to find the roadmap", "What we are working on and what comes next.", "Announcements highlight new releases and upcoming changes. Check them regularly to stay up to date."],
        [:other, "contact-support", "Contacting support", "The best way to reach our team.", "Create a ticket from your dashboard. You can follow the conversation in real time and attach files if needed."],
        [:other, "support-hours", "Support hours", "When you can expect a reply.", "Our team answers tickets on business days. Messages sent outside those hours are answered the next business day."],
        [nil, "getting-started", "Getting started", "A short tour of the dashboard.", "Customize your profile and appearance in Settings, then use the Support section to open tickets and read articles."],
        [nil, "keyboard-and-accessibility", "Accessibility and appearance", "Themes, fonts and dark mode.", "Choose among many themes and fonts and toggle dark mode from the appearance settings."]
      ],
      "es" => [
        [:account_access, "reset-your-password", "Cómo restablecer tu contraseña", "¿Olvidaste tu contraseña? Solicita un enlace en pocos pasos.", "En la página de inicio de sesión elige <strong>Olvidé mi contraseña</strong>. Ingresa tu email y te enviaremos un enlace que expira en poco tiempo."],
        [:account_access, "change-your-email", "Cambiar el email de tu cuenta", "Actualiza el email asociado a tu cuenta.", "Ve a Configuración y edita tu email. Deberás confirmar la nueva dirección antes de que se active."],
        [:technical_issue, "dashboard-not-loading", "El panel no carga", "Qué probar si el panel queda en blanco o lento.", "Actualiza la página, borra la caché del navegador e inténtalo en una ventana privada. Si persiste, abre un ticket indicando tu navegador."],
        [:technical_issue, "file-upload-errors", "Errores al subir archivos", "Por qué un adjunto puede ser rechazado.", "Los adjuntos tienen límites de cantidad, tamaño y tipo. Comprime archivos grandes o conviértelos a un formato admitido."],
        [:billing, "understanding-your-invoice", "Entender tu factura", "Guía rápida de los conceptos de tu factura.", "Cada factura detalla el plan, los complementos y los impuestos. Contacta a soporte si ves un cargo que no reconoces."],
        [:billing, "request-a-refund", "Cómo solicitar un reembolso", "¿Cargo duplicado o incorrecto? Así puedes pedir un reembolso.", "Abre un ticket en la categoría Facturación con el número de factura y una breve descripción."],
        [:feature_request, "suggest-a-feature", "Cómo sugerir una función", "Cuéntanos qué te gustaría ver próximamente.", "Crea un ticket en la categoría Solicitud de función describiendo el problema. Los ejemplos concretos nos ayudan a priorizar."],
        [:feature_request, "product-roadmap", "Dónde ver la hoja de ruta", "En qué trabajamos y qué viene después.", "Los anuncios destacan nuevas versiones y cambios próximos. Revísalos con frecuencia."],
        [:other, "contact-support", "Contactar a soporte", "La mejor forma de comunicarte con el equipo.", "Crea un ticket desde tu panel. Podrás seguir la conversación en tiempo real y adjuntar archivos."],
        [:other, "support-hours", "Horario de soporte", "Cuándo esperar una respuesta.", "Respondemos tickets en días hábiles. Los mensajes fuera de horario se responden el siguiente día hábil."],
        [nil, "getting-started", "Primeros pasos", "Un breve recorrido por el panel.", "Personaliza tu perfil y apariencia en Configuración y usa la sección de Soporte para abrir tickets y leer artículos."],
        [nil, "keyboard-and-accessibility", "Accesibilidad y apariencia", "Temas, fuentes y modo oscuro.", "Elige entre muchos temas y fuentes y activa el modo oscuro desde la configuración de apariencia."]
      ]
    }

    article_data.each do |locale, rows|
      rows.each do |category, slug, title, summary, body|
        Support::Article.find_or_create_by!(locale: locale, slug: slug) do |article|
          article.category = category
          article.title = title
          article.summary = summary
          article.body = "<p>#{body}</p>"
          article.status = :published
          article.published_at = rand(1..30).days.ago
          article.author = superadmin_account
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
end
