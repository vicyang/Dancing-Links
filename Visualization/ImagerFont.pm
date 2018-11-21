package ImagerFont;

use utf8;
use Encode;
use Imager;
use Encode;
use OpenGL;

our $h = 30; # 画布尺寸
our $w = 30;
our $SIZE = 30;
our $font = Imager::Font->new(file  => encode('gbk', 'C:/windows/fonts/arialbd.ttf'), #STXINGKA.TTF
                              size  => $SIZE );

our $bbox = $font->bounding_box(string=>"");

sub get_text_map
{
    our ($font, $SIZE, $w, $h);
    my ( $char, $ref ) = @_;

    my $bbox = $font->bounding_box( string => $char );
    my $img = Imager->new(xsize=>$w, ysize=>$h, channels=>4);

    # # 填充画布背景色
    # $img->box(xmin => 0, ymin => 0, xmax => $w, ymax => $h,
    #         filled => 1, color => '#336699');

    $img->align_string(
               font  => $font,
               text  => $char,
               x     => $w/2.0,
               y     => $h/2.0,
               size  => $SIZE,
               color => 'white',
               aa    => 1,     # anti-alias
               valign => 'center', halign => 'center', 
            );

    $ref->{h} = $h, $ref->{w} = $w;

    my @rasters;
    my @colors;
    for my $y ( reverse 0 .. $h - 1 )
    {
        @colors = $img->getpixel( x => [ 0 .. $w - 1 ], y => [$y] );
        grep { push @rasters, $_->rgba  } @colors;
    }

    $ref->{array} = OpenGL::Array->new( scalar( @rasters ), GL_UNSIGNED_BYTE ); 
    $ref->{array}->assign(0, @rasters);
}

1;