mint
=====
![mint screen shot](mint_screen_shot.png)
#注意/Caution!
mintはまだ開発中の要素が多く、実装されていない機能が沢山あります（演算子とかの基本的な部分も含めて）。もし使用される場合は、ご承知の上での使用をお願いいたします。

#about
mintはリーフと呼ばれるブロックをつなげて形状を記述するCADです。
立方体や円柱といった基本的な形状を表すリーフと、回転や移動、あるいは合成や除算といったブーリアン処理を行うリーフを組み合わせて形を作っていきます。
マウスを使って形状を操作する一般的なCADほど直感的ではないものの、パラメトリックな操作やアルゴリズムによる形状生成が可能（現在は未実装な部分が多いので限定的ですが）です。

##mintとmint-lisp
内部的にはmintはlispのインタプリタ(mint-lisp)として実装されています。.mint形式のファイルをテキストエディタで開いてみるとlispのコードを見ることができます。このレポジトリのコードはUI周りが中心です。

##License
mintはGPL v3を、mint-lispはapache-2.0となります。