module AdminHelper
  # Generate navigation link with active state
  def nav_link(text, path, icon: nil)
    is_active = current_page?(path) || request.path.start_with?(path.split('?').first)
    
    link_to path, class: nav_link_classes(is_active) do
      content_tag(:div, class: 'flex items-center gap-3') do
        concat(heroicon(icon, class: 'w-5 h-5')) if icon
        concat(content_tag(:span, text))
      end
    end
  end
  
  # Navigation link classes
  def nav_link_classes(active = false)
    base = "flex items-center gap-3 px-3 py-2 text-sm font-semibold rounded-[16px] transition-colors"
    
    if active
      "#{base} bg-[#FFC220] text-[#0053E2] shadow-md"
    else
      "#{base} text-white hover:bg-[#003299]"
    end
  end
  
  # Simple heroicon helper (outline style)
  def heroicon(name, **options)
    svg_class = options[:class] || 'w-6 h-6'
    
    icons = {
      'chart-bar' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>',
      'cube' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>',
      'briefcase' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>',
      'folder' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"></path>',
      'tag' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>',
      'calculator' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"></path>',
      'receipt-percent' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16l3.5-2 3.5 2 3.5-2 3.5 2zM10 8.5a.5.5 0 11-1 0 .5.5 0 011 0zm5 5a.5.5 0 11-1 0 .5.5 0 011 0z"></path>',
      'shopping-cart' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"></path>',
      'clipboard-check' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"></path>',
      'office-building' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>',
      'currency-dollar' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>',
      'users' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path>',
      'cog' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>',
      'clock' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>',
      'exclamation' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>',
      'check-circle' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>',
      'x-circle' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"></path>',
      'information-circle' => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>'
    }
    
    path = icons[name] || icons['cube']
    
    content_tag(:svg, 
      path.html_safe,
      class: svg_class,
      fill: 'none',
      stroke: 'currentColor',
      viewBox: '0 0 24 24'
    )
  end
  
  # Flash message classes
  def flash_class(type)
    case type.to_s
    when 'notice', 'success'
      'bg-green-50 text-green-800 border border-green-200'
    when 'alert', 'error'
      'bg-red-50 text-red-800 border border-red-200'
    when 'warning'
      'bg-[#FFC220]/20 text-[#0053E2] border border-[#FFC220]'
    else
      'bg-[#E9F1FE] text-[#0053E2] border border-[#0053E2]/20'
    end
  end
  
  # Flash message icon
  def flash_icon(type)
    icon_name = case type.to_s
    when 'notice', 'success' then 'check-circle'
    when 'alert', 'error' then 'x-circle'
    when 'warning' then 'exclamation'
    else 'information-circle'
    end
    
    heroicon(icon_name, class: 'w-5 h-5')
  end
  
  # Status badge
  def status_badge(status, text = nil)
    text ||= status.to_s.titleize
    
    classes = case status.to_s
    when 'active', 'completed', 'paid', 'shipped'
      'bg-green-100 text-green-800'
    when 'inactive', 'cancelled', 'refunded'
      'bg-red-100 text-red-800'
    when 'pending', 'processing'
      'bg-[#FFC220] text-[#0053E2]'
    when 'draft'
      'bg-gray-100 text-gray-800'
    else
      'bg-[#E9F1FE] text-[#0053E2]'
    end
    
    content_tag(:span, text, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold #{classes}")
  end
  
  # Format currency
  def format_currency(amount)
    number_to_currency(amount, unit: '₮', separator: '.', delimiter: ',', format: '%n %u')
  end
  
  # Format percentage
  def format_percentage(value)
    number_to_percentage(value, precision: 1)
  end
  
  # Page title helper
  def admin_page_title(title)
    content_for(:title, title)
    content_tag(:div, class: 'mb-6') do
      content_tag(:h1, title, class: 'text-2xl font-black text-[#0053E2]')
    end
  end
  
  # Admin Button Helper
  # Primary button: admin_button('Шинэ нэмэх', new_admin_product_path, icon: 'plus')
  # Secondary button: admin_button('Цуцлах', admin_products_path, variant: 'secondary')
  # Link button: admin_button('Засах', edit_admin_product_path(product), variant: 'link')
  # Icon button: admin_button(nil, edit_admin_product_path(product), variant: 'icon', icon: 'edit')
  def admin_button(text = nil, href = nil, variant: 'primary', icon: nil, icon_position: 'left', method: nil, data: {}, classes: '')
    render 'admin/shared/button', 
           text: text, 
           href: href, 
           variant: variant, 
           icon: icon, 
           icon_position: icon_position,
           method: method,
           data: data,
           classes: classes
  end
end
