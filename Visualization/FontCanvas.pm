package FontCanvas;

use strict;
use OpenGL;
use Imager;
use threads::shared;

our $SIZE = 20;
our $font;
our $bbox;
our $img;
our $ybase = 0.0;
our $xbase = 10.0;  # 向右偏移
our $h = 400;
our $w = 400;

sub init
{
    our ($SIZE, $font, $bbox, $img);
    my ($canvas) = @_;

    $font = Imager::Font->new(file  => 'C:/windows/fonts/consola.ttf', #STXINGKA.TTF
                              size  => $SIZE );
    $bbox = $font->bounding_box( string => "a" );
    $img = Imager->new(xsize=>$w, ysize=>$h, channels=>4);
    $ybase = 0.0;

    # 填充画布背景色
    $img->box(xmin => 0, ymin => 0, xmax => $w, ymax => $h,
            filled => 1, color => '#336699');

    my @rasters;
    my @colors;
    for my $y ( reverse 0 .. $h - 1 )
    {
        @colors = $img->getscanline( y => $y );
        grep { push @rasters, $_->rgba  } @colors;
    }

    $canvas->{w} = $w;
    $canvas->{h} = $h;
    $canvas->{array} = OpenGL::Array->new( scalar(@rasters), GL_UNSIGNED_BYTE );
    $canvas->{array}->assign(0, @rasters);
}

sub update_text
{
    our ($font, $SIZE, $img, $xbase, $ybase, $bbox);
    our ($h, $w);
    my ( $string, $canvas ) = @_;

    $ybase += $bbox->font_height + 2.0;

    $img->string(
               font  => $font,
               text  => $string,
               x     => $xbase,
               y     => $ybase,
               size  => $SIZE,
               color => 'gold',
               aa    => 1,     # anti-alias
            );
    
    my @rasters;
    my @colors;
    for my $y ( reverse 0 .. $h - 1 )
    {
        @colors = $img->getscanline( y => $y );
        grep { push @rasters, $_->rgba  } @colors;
    }

    $canvas->{array} = OpenGL::Array->new( scalar(@rasters), GL_UNSIGNED_BYTE );
    $canvas->{array}->assign(0, @rasters);
}

1;