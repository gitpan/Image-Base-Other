# Copyright 2011 Kevin Ryde

# This file is part of Image-Base-Other.
#
# Image-Base-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Other.  If not, see <http://www.gnu.org/licenses/>.


package Image::Base::SVGout;
use 5.006;
use strict;
use Carp;
use vars '$VERSION', '@ISA';

use Image::Base;
@ISA = ('Image::Base');

$VERSION = 7;

# uncomment this to run the ### lines
#use Devel::Comments '###';

sub new {
  my ($class, %params) = @_;

  if (ref $class) {
    my $self = $class;
    $class = ref $self;
    if ($self->{'-filehandle'}) {
      croak "Cannot clone SVGout after drawing begun";
    }
    %params = (%$self, %params);  # inherit
    ### copy params: \%params
  }

  if (defined $params{'-file'}) {
    croak "Cannot load initial -file, Image::Base::SVGout is output-only";
  }
  return bless \%params, $class;
}

sub DESTROY {
  my ($self) = @_;
  if ($self->{'-filehandle'}) {
    $self->save;  # closing </svg>
  }
}

sub set {
  my ($self, %param) = @_;
  if ($self->{'-filehandle'}) {
    foreach my $key ('-file', '-title', '-description') {
      if (exists $param{$key}) {
        _nochange_str ($self, $key, $param{$key});
      }
    }
    foreach my $key ('-width', '-height') {
      if (exists $param{$key}) {
        _nochange_str ($self, $key, $param{$key});
      }
    }
  }
  %$self = (%$self, %param);
}
sub _nochange_str {
  my ($self, $key, $newval) = @_;
  if (defined $self->{$key}
      && (! defined $newval
          || $newval ne $self->{$key})) {
    croak "Cannot change $key after output has begun";
  }
}
sub _nochange_num {
  my ($self, $key, $newval) = @_;
  if (defined $self->{$key}
      && (! defined $newval
          || $newval != $self->{$key})) {
    croak "Cannot change $key after output has begun";
  }
}

sub _out {
  my $self = shift;
  my $fh = $self->{'-filehandle'} || _start_out($self);
  print $fh @_, "\n"
    or croak "Error writing $self->{'-file'}: $!";
}



  # require Fcntl;
  # sysopen FH, $filename, Fcntl::O_WRONLY() | Fcntl::O_TRUNC() | Fcntl::O_CREAT()
  #   or croak "Cannot create $filename: $!";
  #
  # if (! $self->save_fh (\*FH)) {
  #   my $err = "Error writing $filename: $!";
  #   { local $!; close FH; }
  #   croak $err;
  # }
  # close FH
  #   or croak "Error closing $filename: $!";

sub _start_out {
  my ($self) = @_;

  if ($self->{'save_done'}) {
    croak "Cannot draw more after save()";
  }

  my $filename = $self->{'-file'};
  if (! defined $filename) {
    croak "No -file set";
  }

  my $width = $self->{'-width'};
  my $height = $self->{'-height'};
  if (! defined $width || ! defined $height) {
    croak "No -width / -height set";
  }

  my $class = ref $self;
  my $version = $self->VERSION;

  foreach ($width,$height,$class,$version) {
    $_ = _entitize($_);
  }

  my ($title, $description);
  open my $fh, '>', $filename
    or croak "Cannot write file $filename: $!";

  print $fh <<"HERE",
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height">
<!-- Generated by $class version $version -->
HERE

    (defined ($title = $self->{'-title'})
     ? ("<title>", _entitize($title), "</title>\n")
     : ()),

       (defined ($description = $self->{'-description'})
        ? ("<desc>", _entitize($self->{'-description'}), "</desc>")
        : ())

         or croak "Error writing $filename: $!";

  return ($self->{'-filehandle'} = $fh);
}

sub _close_out {
  my ($self) = @_;

  if (my $fh = delete $self->{'-filehandle'}) {
    close $fh or croak "Error closing $self->{'-file'}: $!";
  }
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-SVGout save(): @_
  if (@_ > 1) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### $filename

  _out ($self, "</svg>");
  $self->{'save_done'} = 1;
  _close_out ($self);
}

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Image-Base-SVGout xy(): @_[1 .. $#_]

  if (@_ == 3) {
    return undef;  # no fetch
  } else {
    _out ($self,
          '<rect x="', $x,
          '" y="', $y,
          '" width="1" height="1" fill="', _entitize($colour), '"/>');
  }
}

sub rectangle {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### Image-Base-SVGout rectangle(): @_[1 .. $#_]

  $fill ||= ($x1 == $x2 || $y1 == $y2);  # 1xN or Nx1 done filled
  if (! $fill) {
    $x1 += .5;  # for stroke width 1
    $y1 += .5;
    $x2 -= .5;
    $y2 -= .5;
  }
  _out ($self,
        '<rect x="', $x1,
        '" y="', $y1,
        '" width="',  $x2-$x1+1,
        '" height="', $y2-$y1+1, '" ',
        ($fill?'fill':'stroke'), '="', _entitize($colour),
        '"/>');
}

sub ellipse {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### Image-Base-SVGout rectangle(): @_[1 .. $#_]

  $fill ||= ($x1 == $x2 || $y1 == $y2);  # 1xN or Nx1 done filled
  my $rx = ($x2-$x1+1) / 2;
  my $ry = ($y2-$y1+1) / 2;
  if (! $fill) {
    $rx -= .5;  # for stroke width 1
    $ry -= .5;
  }
  _out ($self,
        '<ellipse cx="' .(($x1+$x2+1) / 2),
        '" cy="', (($y1+$y2+1) / 2),
        '" rx="', $rx,
        '" ry="', $ry,'" ',
        ($fill?'fill':'stroke'),'="', _entitize($colour), '"/>');
}

sub line {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### Image-Base-SVGout rectangle(): @_[1 .. $#_]

  _out ($self,
        '<line x1="', $x1+.5,
        '" y1="', $y1+.5,
        '" x2="', $x2+.5,
        '" y2="', $y2+.5,
        '" stroke="', _entitize($colour),
        '" stroke-linecap="square"/>');
}

sub diamond {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### Image-Base-SVGout diamond(): @_[1 .. $#_]

  $fill ||= ($x1 == $x2 || $y1 == $y2);  # 1xN or Nx1 done filled
  if ($fill) {
    $x2++;
    $y2++;
  } else {
    $x1 += .5;  # for stroke width 1
    $y1 += .5;
    $x2 += .5;
    $y2 += .5;
  }
  my $xm = ($x1+$x2)/2;
  my $ym = ($y1+$y2)/2;
  _out ($self,
        '<polygon points="',
        $xm,',',$y1,' ',
        $x1,',',$ym,' ',
        $xm,',',$y2,' ',
        $x2,',',$ym,'" ',
        ($fill?'fill':'stroke'),'="', _entitize($colour), '"/>');
}

sub load {
  my ($self, $filename) = @_;
  croak "Image::Base::SVGout is output-only";
}

# Could leave wide chars as utf8 bytes, and latin1 bytes upgraded, if apply
# the right layers to the open and in new enough perl.  For now send all
# non-ascii-printable to numbered.
#
my %entity = ('&' => '&amp;',
              '"' => '&quot;',
              '<' => '&lt;',
              '>' => '&gt;',
             );
sub _entitize {
  my ($value) = @_;
  $value =~ s{([&"<>]|[^\t\r\n\x20-\x7F])}
             { $entity{$1} || ('&#'.ord($1).';') }eg;
  return $value;
}

1;
__END__

=for stopwords SVGout filename Ryde SVG

=head1 NAME

Image::Base::SVGout -- SVG image file output

=head1 SYNOPSIS

 use Image::Base::SVGout;
 my $image = Image::Base::SVGout->new (-width => 100,
                                                       -height => 100);
 $image->set (-file => '/some/filename.svg');
 $image->rectangle (0,0, 99,99, 'red');
 $image->xy (20,20, '#FF00FF');
 $image->line (50,50, 70,70, 'white');
 $image->line (50,50, 70,70, 'green');
 $image->save;

=head1 CLASS HIERARCHY

C<Image::Base::SVGout> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::SVGout

=head1 DESCRIPTION

C<Image::Base::SVGout> extends C<Image::Base> to write SVG
format image files progressively.

This is an unusual C<Image::Base> module in that it writes to its C<-file>
during drawing, rather than holding an image in memory.  This means drawing
operations are just prints of SVG elements to the file, but also means a
C<-file> must be specified before drawing.  The final C<save()> just writes
a closing C<E<lt>/svgE<gt>> to the file.

The C<Image::Base> functions are pixel oriented so aren't really the sort of
thing SVG is meant for, but this module at least makes it possible to get
some SVG out of C<Image::Base> style drawing code.  SVG has many more
features than can be accessed with the functions here, and it's just XML
text so often isn't hard to spit out directly instead too.

See C<Image::Base::SVG> for similar SVG output but going to an C<SVG.pm>
object.

=head1 FUNCTIONS

=over 4

=item C<$image = Image::Base::SVGout-E<gt>new (key=E<gt>value,...)>

Create and return a new SVGout image object.

    $image = Image::Base::SVGout->new (-width => 200, -height => 100);

=item C<$newimage = $image-E<gt>new (key=E<gt>value,...)>

Clone C<$image> and apply the given settings.  This can only be done before
drawing has begun.

=item C<$colour = $image-E<gt>xy ($x, $y)>

Get an individual pixel.  The return is always C<undef> since there's no
support for picking out elements etc from the drawn SVG.

=item C<$image-E<gt>load ()>

=item C<$image-E<gt>load ($filename)>

Loading is not possible with this module.

=item C<$image-E<gt>save ()>

=item C<$image-E<gt>save ($filename)>

Save the image to an SVG file, either the current C<-file> option, or set
that option to C<$filename> and save to there.

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer)

=item C<-height> (integer)

Set the SVG canvas size in pixels.  These must be set before the first
drawing operation, and cannot be changed after the first drawing operation
(because they're printed in the initial SVG header).

=back

=head1 SEE ALSO

L<Image::Base>,
L<Image::Base::SVG>

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-other/index.html

=head1 LICENSE

Image-Base-Other is Copyright 2010, 2011 Kevin Ryde

Image-Base-Other is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Image-Base-Other is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Image-Base-Other.  If not, see <http://www.gnu.org/licenses/>.

=cut
