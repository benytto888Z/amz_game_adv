import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'classic_font.dart';

/// Local simulation only; it does not read the panel's physical LEDs.
class MatrixPreview extends StatefulWidget {
  const MatrixPreview({super.key, required this.text, required this.rgb,
    required this.scrolling, required this.intervalMs, required int iconId});
  final String text;
  final int rgb;
  final bool scrolling;
  final int intervalMs;
  @override State<MatrixPreview> createState()=>_MatrixPreviewState();
}

class _MatrixPreviewState extends State<MatrixPreview> {
  Timer? timer;
  int x=32;
  @override void initState(){super.initState();_restart();}
  @override void didUpdateWidget(covariant MatrixPreview old){
    super.didUpdateWidget(old);
    if(old.text!=widget.text || old.scrolling!=widget.scrolling || old.intervalMs!=widget.intervalMs) _restart();
  }
  void _restart(){
    timer?.cancel(); x=widget.scrolling?32:0;
    if(widget.scrolling){
      timer=Timer.periodic(Duration(milliseconds:widget.intervalMs.clamp(20,500).toInt()),(_){
        if(!mounted)return;
        setState((){x--;if(x <= -widget.text.length*6)x=32;});
      });
    }
  }
  @override void dispose(){timer?.cancel();super.dispose();}
  @override Widget build(BuildContext context)=>AspectRatio(aspectRatio:4,
      child:CustomPaint(painter:_MatrixPainter(widget.text,widget.rgb,x,Theme.of(context).colorScheme.surfaceContainerHighest)));
}

class _MatrixPainter extends CustomPainter {
  _MatrixPainter(this.text,this.rgb,this.offset,this.offColor);
  final String text; final int rgb,offset; final Color offColor;
  @override void paint(Canvas canvas,Size size){
    final step=math.min(size.width/32,size.height/8);
    final startX=(size.width-step*32)/2, startY=(size.height-step*8)/2;
    final on=Paint()..color=Color(0xff000000|rgb);
    final off=Paint()..color=offColor;
    for(int y=0;y<8;y++) for(int x=0;x<32;x++) {
      final charX=x-offset;
      var lit=false;
      if(charX>=0 && y<8) {
        final charIndex=charX~/6, col=charX%6;
        if(charIndex<text.length && col<5) {
          final code=text.codeUnitAt(charIndex);
          if(code>=32 && code<=126) lit=(classicFontAscii[(code-32)*5+col] & (1<<y))!=0;
        }
      }
      canvas.drawCircle(Offset(startX+(x+.5)*step,startY+(y+.5)*step),step*.36,lit?on:off);
    }
  }
  @override bool shouldRepaint(covariant _MatrixPainter old)=>old.text!=text || old.rgb!=rgb || old.offset!=offset || old.offColor!=offColor;
}
