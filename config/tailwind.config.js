const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  darkMode: 'class',
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Zalando Sans', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        // Job509 Custom Color Palette
        'job-blue': {
          DEFAULT: '#2563EB',
          light: '#60A5FA',
          dark: '#1D4ED8',
        },
        'job-red': {
          DEFAULT: '#DC2626',
          light: '#F87171',
          dark: '#B91C1C',
        },
      },
      // Flat design - minimal border radius
      borderRadius: {
        'none': '0',
        'sm': '0.125rem',
        'DEFAULT': '0.125rem',
        'md': '0.25rem',
        'lg': '0.25rem',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ]
}
