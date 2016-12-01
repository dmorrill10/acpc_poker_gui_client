var path = require('path')
var webpack = require('webpack')

module.exports = {
  devtool: 'source-map',
  context: __dirname,
  entry: path.join(__dirname, 'frontend', 'entry'),
  output: {
    path: path.join(__dirname, 'public', 'assets'),
    filename: 'bundle.js',
    publicPath: '/assets/'
  },
  plugins: [
    new webpack.optimize.UglifyJsPlugin({
      compressor: {
        warnings: false
      }
    }),
    new webpack.optimize.OccurrenceOrderPlugin(),
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery'
    })
  ],
  module: {
    loaders: [{
      test: /\.(jpe?g|png|gif|ttf|eot|svg|woff)(\??v?=?[0-9]?\.?[0-9]?\.?[0-9]?)?$/,
      loaders: ["url-loader"]
    }, {
      test: /\.css$/,
      loaders: ['style', 'css']
    }, {
      test: /\.s[ca]ss$/,
      loaders: ['style', 'css?sourceMap', 'sass?sourceMap']
    }, {
      test: /\.jsx?$/,
      loaders: ['babel-loader'],
      exclude: /node_modules/
    }]
  },
  sassLoader: {
    includePaths: [
      path.resolve(__dirname, "./node_modules"),
    ].concat(require("bourbon").includePaths)
  }
}
