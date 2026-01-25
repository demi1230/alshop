module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        blue: {
          100: '#E9F1FE',
          300: '#0053E2',
          400: '#003299',
          500: '#001E60'
        },
        yellow: {
          300: '#FFC220',
          400: '#D6A72C'
        },
        grey: {
          200: '#CACACA',
          300: '#989898',
          400: '#656565',
          500: '#333333'
        }
      },
      fontFamily: {
        sans: ['Montserrat', 'sans-serif']
      },
      borderRadius: {
        'button': '16px'
      }
    }
  },
  plugins: []
}
