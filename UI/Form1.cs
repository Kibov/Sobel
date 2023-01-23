using System.Runtime.InteropServices;

namespace UI
{
    public partial class Form1 : Form
    {

        public unsafe class AsmProxySobel
        {
            [DllImport("ASMSobel.dll")]
            private static extern int Sobel(byte[] gray, int[] calculated, int[] help, int height, int width, int bytes);

            public int ExecuteSobel(byte[] gray, int[] calculated, int[] help, int height, int width, int bytes)
            {
                return Sobel(gray, calculated, help, height, width, bytes);
            }
        }

        [DllImport("CPPSobel.dll")]
        private static extern void SobelCPP(byte[] gray, int[] calculated, int height, int width, int bytes);
        

        Bitmap sourceImageBmp;
        Image sourceImage;

        byte[] imageWithHeaders;
        byte[] imageWithoutHeaders;
        byte[] header;
        byte[] outByteImage;
        int bitWidth;
        int bitHeight;

        public Form1()
        {
            InitializeComponent();
            asmRadioButton.Checked = true;
        }



        private void button1_Click_1(object sender, EventArgs e)
        {
            using (OpenFileDialog ofd = new OpenFileDialog())
            {
                ofd.InitialDirectory = @"C:\Documents";
                ofd.Filter = "bmp files (*.bmp)|*.bmp";
                ofd.FilterIndex = 2;
                ofd.RestoreDirectory = true;

                if (ofd.ShowDialog() == DialogResult.OK)
                {
                    var fileStream = ofd.OpenFile();

                    using (StreamReader sr = new StreamReader(fileStream))
                    {
                        pictureBox1.Image = new Bitmap(fileStream);

                        sourceImage = pictureBox1.Image;
                        sourceImageBmp = new Bitmap(pictureBox1.Image);

                        imageWithHeaders = ImgToByte(sourceImage);
                        header = imageWithHeaders.Take(54).ToArray();
                        imageWithoutHeaders = new byte[imageWithHeaders.Length - 54];

                        for (int i = 54; i < imageWithHeaders.Length; i++)
                        {
                            imageWithoutHeaders[i - 54] = imageWithHeaders[i];
                        }

                        bitWidth = BitConverter.ToInt32(header.Skip(18).Take(4).ToArray(), 0) * 3;
                        bitHeight = BitConverter.ToInt32(header.Skip(22).Take(4).ToArray(), 0);

                        if (bitWidth % 4 != 0)
                        {
                            bitWidth = (bitWidth / 4 + 1) * 4;
                        }

                        outByteImage = new byte[imageWithHeaders.Length];

                        pictureBox1.Image = ByteToImg(imageWithHeaders);
                    }
                }
            }
        }

        private void Run_Click(object sender, EventArgs e)
        {

            var watch = new System.Diagnostics.Stopwatch();


            AsmProxySobel asmp = new AsmProxySobel();

            for (int i = 0; i < imageWithoutHeaders.Length; i += 3)
            {
                int gray = (int)((imageWithoutHeaders[i] + imageWithoutHeaders[i + 1] + imageWithoutHeaders[i + 2]) / 3.0);
                imageWithoutHeaders[i] = (byte)gray;
                imageWithoutHeaders[i + 1] = (byte)gray;
                imageWithoutHeaders[i + 2] = (byte)gray;
            }


            int arraySize = bitHeight * bitWidth;
            int[] help = new int[arraySize];
            int[] calculated = new int[arraySize];
            if (asmRadioButton.Checked == true)
            {
                watch.Start();
                for (int i = 0; i < trackBar1.Value; i++)
                {
                    asmp.ExecuteSobel(imageWithoutHeaders, calculated, help, bitHeight, bitWidth, arraySize);
                }
                watch.Stop();
            }
            else {
                watch.Start();
                for (int i = 0; i < trackBar1.Value; i++) {
                    SobelCPP(imageWithoutHeaders, calculated, bitHeight, bitWidth, arraySize);
                }
                watch.Stop();
            }


            for (int i = 0; i < 54; i++)
            {
                outByteImage[i] = header[i];
            }
            for (int i = 54; i < outByteImage.Length; i++)
            {
                outByteImage[i] = (byte)Math.Min(255, Math.Max(0, calculated[i - 54]));
            }

            var elapsedTime = watch.Elapsed;

            label2.Text = elapsedTime.ToString("mm\\:ss\\.fff");

            pictureBox2.Image = ByteToImg(outByteImage);

        }

        private void button3_Click(object sender, EventArgs e)
        {
            using (var sfd = new SaveFileDialog())
            {
                sfd.InitialDirectory = @"C:\Documents";
                sfd.Filter = "bmp files (*.bmp)|*.bmp";
                sfd.FilterIndex = 2;
                sfd.RestoreDirectory = true;

                if (sfd.ShowDialog() == DialogResult.OK)
                {
                    var fileStream = sfd.OpenFile();
                    pictureBox2.Image.Save(fileStream, System.Drawing.Imaging.ImageFormat.Bmp);
                }
            }
        }


        private Image ByteToImg(byte[] img)
        {
            ImageConverter converter = new ImageConverter();
            return (Image)converter.ConvertFrom(img);
        }

        private static byte[] ImgToByte(Image img)
        {
            ImageConverter converter = new ImageConverter();
            byte[] image = (byte[])converter.ConvertTo(img, typeof(byte[]));

            return image;
        }


    }

}