const path = require('path');
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = {
    mode: 'production',
    entry: './src/server.js',
    output: {
        path: path.join(__dirname, 'dist'),
        publicPath: '/',
        filename: 'express.js',
    },
    target: 'node',
    plugins: [
        new CopyWebpackPlugin({
            patterns: [
                { from: 'src/html', to: 'html' }
            ]
        })
    ],
};